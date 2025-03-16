import 'dart:async';

import 'package:squadron/squadron.dart';
import 'package:test/test.dart' as env;

import '_test_context_stub.dart'
    if (dart.library.io) '_test_context_vm.dart'
    if (dart.library.js_interop) '_test_context_web.dart' as impl;
import 'test_entry_points.dart';
import 'test_exception.dart';
import 'test_result.dart';
import 'test_timeout.dart';

enum RunMode {
  discover,
  launch,
}

class TestContext {
  TestContext._(this.runMode, this.workerPlatform);

  bool get hasImageCodecs => impl.hasImageCodecs;

  bool get hasChromiumBreakIterators => impl.hasChromiumBreakIterators;

  bool get supportsWasmGC => impl.supportsWasmGc;

  bool get isCrossOriginIsolated => impl.isCrossOriginIsolated;

  static const _mixedTargets = {
    SquadronPlatformType.js: SquadronPlatformType.wasm,
    SquadronPlatformType.wasm: SquadronPlatformType.js,
  };

  static Future<void> run(
    void Function(TestContext?) executor, {
    bool mixedContext = true,
  }) async {
    final init = [TestContext.init(RunMode.launch, '~')];
    if (mixedContext) {
      final mixedTarget = _mixedTargets[Squadron.platformType];
      if (mixedTarget != null && mixedTarget != Squadron.platformType) {
        init.add(TestContext.init(RunMode.launch, '~', mixedTarget));
      }
    }
    await Future.wait(init).then((contexts) => contexts.forEach(executor));
  }

  static Future<TestContext?> init(RunMode runMode,
      [String? root, SquadronPlatformType? workerPlatform]) async {
    workerPlatform ??= impl.platform;
    final testContext = TestContext._(runMode, workerPlatform);
    try {
      await testContext.entryPoints.set(root, workerPlatform);
      return testContext;
    } catch (_) {
      return null;
    }
  }

  final RunMode runMode;

  final testResults = <TestResult>[];

  bool _cancelled = false;
  bool get isCancelled => _cancelled;

  int get pending => testResults.where((r) => r.isPending).length;

  Future<void> wait() => Future.wait(testResults.map((r) => r.done));

  void cancel() {
    _cancelled = true;
  }

  void discover(void Function(TestContext) testSuite) {
    if (runMode != RunMode.discover) {
      throw UnsupportedError('Test context was not initialized for discovery');
    }
    testSuite(this);
  }

  void launch(void Function() testSuite) => env.group(
        '${runnerPlatform.shortLabel} runner / ${workerPlatform.shortLabel} workers',
        testSuite,
      );

  SquadronPlatformType get runnerPlatform => impl.platform;
  String get runnerPlatformName =>
      '${impl.platformName} (${runnerPlatform.label})';

  final SquadronPlatformType workerPlatform;
  String get workerPlatformName =>
      '${impl.platformName} (${workerPlatform.label})';

  final entryPoints = TestEntryPoints();

  final onlyTests = <Pattern>{};

  String get platforms =>
      '${runnerPlatform.shortLabel}/${workerPlatform.shortLabel}';

  String _testPath = '';

  TestResult _enterTest(String label) {
    final result = TestResult(_testPath, label);
    _testPath = result.testPath;
    return result;
  }

  TestResult _enterGroup(String label) {
    final result = TestResult(_testPath, label);
    _testPath = result.testPath;
    return result;
  }

  void _leave(TestResult result) {
    _testPath = result.parentPath;
  }

  bool _skipTest(bool skip, TestResult result) =>
      skip || (onlyTests.isNotEmpty && !onlyTests.any(result.isMatch));

  void test(String description, dynamic Function() body,
      {bool skip = false, String? testOn}) {
    final result = _enterTest(description);
    testResults.add(result);
    if (runMode == RunMode.discover) {
      _knownTests.add(result.testPath);
      result.pass();
    } else if (_skipTest(skip, result)) {
      env.test(description, body, skip: true);
      result.skip();
    } else {
      env.test(description, () async {
        if (_cancelled) {
          result.cancel();
          Error.throwWithStackTrace(TestCancelledException(), StackTrace.empty);
        } else {
          final timeout = TestTimeout(Duration(seconds: 25));
          await Future.any([
            Future.value(body()),
            timeout.completion,
          ]).catchError((ex, st) {
            result.fail(ex, st);
            Error.throwWithStackTrace(ex, st);
          }).whenComplete(() {
            timeout.cancel();
            result.pass();
          });
        }
      }, testOn: testOn);
    }
    _leave(result);
  }

  void group(String description, dynamic Function() body,
      {bool skip = false, String? testOn}) {
    final result = _enterGroup(description);
    if (runMode == RunMode.discover) {
      _knownGroups.add(result.testPath);
      body();
    } else if (!_skipTest(skip, result)) {
      env.group(description, body, testOn: testOn);
    }
    _leave(result);
  }

  final _knownGroups = <String>{};

  Iterable<String> get knownGroups => _knownGroups.where(
      (_) => true); // force iterable to avoid exposing the underlying list

  Iterable<({String label, int tests})> get rootGroups sync* {
    for (var group in _knownGroups) {
      if (_knownGroups.any((g) => g != group && group.startsWith(g))) {
        continue;
      }
      final count = _knownTests.where((t) => t.startsWith(group)).length;
      yield (label: group, tests: count);
    }
  }

  final _knownTests = <String>{};

  Iterable<String> get knownTests => _knownTests.where(
      (_) => true); // force iterable to avoid exposing the underlying list
}

extension on SquadronPlatformType {
  String get shortLabel {
    if (isVm) return 'VM';
    if (isJs) return 'JS';
    if (isWasm) return 'WASM';
    return label;
  }
}
