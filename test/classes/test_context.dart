import 'dart:async';

import 'package:squadron/squadron.dart';
import 'package:test/test.dart' as env;

import '_test_context_stub.dart'
    if (dart.library.io) '_test_context_vm.dart'
    if (dart.library.js_interop) '_test_context_web.dart' as impl;
import 'platform.dart';
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

  Future<void> waitForCompletion() =>
      Future.wait(testResults.map((r) => r.completion));

  void cancel() {
    _cancelled = true;
    for (var t in testResults) {
      t.cancel();
    }
  }

  void discover(void Function(TestContext) testSuite) {
    if (runMode != RunMode.discover) {
      throw UnsupportedError('Test context was not initialized for discovery');
    }
    testSuite(this);
  }

  void launch(void Function() testSuite) => env.group(
        '${clientPlatform.label} client / ${workerPlatform.label} workers',
        testSuite,
      );

  SquadronPlatformType get clientPlatform => impl.platform;
  String get clientPlatformName =>
      '${impl.platformName} (${clientPlatform.label})';

  final SquadronPlatformType workerPlatform;
  String get workerPlatformName =>
      '${impl.platformName} (${workerPlatform.label})';

  final entryPoints = TestEntryPoints();

  final onlyTests = <Pattern>{};

  String get platforms => '${clientPlatform.label}/${workerPlatform.label}';

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

  void setUpAll(dynamic Function() callback) {
    if (runMode == RunMode.discover) return;
    env.setUpAll(callback);
  }

  void tearDownAll(dynamic Function() callback) {
    if (runMode == RunMode.discover) return;
    env.tearDownAll(callback);
  }

  void skip(String label, dynamic Function() body, {bool skip = false}) {
    final result = _enterTest(label);
    testResults.add(result);
    if (runMode == RunMode.discover) {
      _knownTests.add(result.testPath);
    } else {
      print('[$platforms] Skip test "${result.testPath}"');
    }
    result.skip();
    _leave(result);
  }

  bool _skipTest(bool skip, TestResult result) =>
      skip || (onlyTests.isNotEmpty && !onlyTests.any(result.isMatch));

  void test(String label, dynamic Function() body, {bool skip = false}) {
    final result = _enterTest(label);
    testResults.add(result);
    if (runMode == RunMode.discover) {
      _knownTests.add(result.testPath);
      result.pass();
    } else if (_skipTest(skip, result)) {
      print('[$platforms] Skip test "${result.testPath}"');
      result.skip();
    } else if (_cancelled) {
      print('[$platforms] Test "${result.testPath}" cancelled');
      result.cancel();
    } else {
      env.test(label, () async {
        if (_cancelled) {
          print('[$platforms] Test "${result.testPath}" cancelled');
          result.cancel();
          throw TestCancelledException();
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
      });
    }
    _leave(result);
  }

  void group(String label, dynamic Function() body, {bool skip = false}) {
    final result = _enterGroup(label);
    if (runMode == RunMode.discover) {
      _knownGroups.add(result.testPath);
      body();
    } else if (_skipTest(skip, result)) {
      // print('[$platforms] Skip group "${result.testPath}"');
    } else {
      env.group(label, body);
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

typedef ExceptionHandler = void Function(Object ex, [StackTrace? st]);

ExceptionHandler uncaughtExceptionHandler(String info) => (ex, [st]) {
      $log('[$info] EXCEPTION $ex');
      $log('[$info] STACKTRACE: $st');
    };
