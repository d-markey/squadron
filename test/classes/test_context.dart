import 'dart:async';

import 'package:squadron/squadron.dart';
import 'package:test/test.dart' as env;

import '_test_context_stub.dart'
    if (dart.library.io) '../workers/vm/_test_context.dart'
    if (dart.library.html) '../workers/js/_test_context.dart'
    if (dart.library.js_interop) '../workers/wasm/_test_context.dart' as impl;
import 'test_entry_points.dart';

class TestContext {
  TestContext._(this.workerPlatform);

  bool get hasImageCodecs => impl.hasImageCodecs;

  bool get hasChromiumBreakIterators => impl.hasChromiumBreakIterators;

  bool get supportsWasmGC => impl.supportsWasmGc;

  bool get isCrossOriginIsolated => impl.isCrossOriginIsolated;

  static Future<TestContext?> init(String root,
      [SquadronPlatformType? workerPlatform]) async {
    workerPlatform ??= impl.platform;
    final testContext = TestContext._(workerPlatform);
    try {
      await testContext.entryPoints.set(root, workerPlatform);
      return testContext;
    } catch (_) {
      return null;
    }
  }

  static const cancelled = '@@CANCELLED@@';

  Completer<void>? _completer;
  int _pending = 0;
  bool _canceled = false;
  bool _discovery = false;

  int get pending => _pending;

  void _checkDone() {
    _pending -= 1;
    if (_pending == 0 && _completer?.isCompleted == false) {
      _completer!.complete();
      _completer = null;
    }
  }

  Future<bool> get done =>
      _completer?.future.then((_) => _canceled) ?? Future.value(_canceled);

  void cancel() {
    if (_completer?.isCompleted == false) {
      _canceled = true;
      _completer!.complete();
      _completer = null;
    }
  }

  void run(void Function() testSuite) {
    if (_completer == null) {
      _canceled = false;
      _completer = Completer();
      testResults.clear();
    }
    env.group(
      '${clientPlatform.label} client / ${workerPlatform.label} workers',
      testSuite,
    );
  }

  void discover(void Function(TestContext) testSuite) {
    if (_completer == null) {
      _discovery = true;
      _completer = Completer();
      _completer!.future.whenComplete(() => _discovery = false);
    }
    testSuite(this);
  }

  SquadronPlatformType get clientPlatform => impl.platform;
  String get clientPlatformName =>
      '${impl.platformName} (${clientPlatform.label})';

  final SquadronPlatformType workerPlatform;
  String get workerPlatformName =>
      '${impl.platformName} (${workerPlatform.label})';

  final entryPoints = TestEntryPoints();

  final onlyTests = <Pattern>{};

  final testResults = <String, TestResult>{};

  String _testPath = '';

  String get platforms => '${clientPlatform.label}/${workerPlatform.label}';

  void skip(String label, dynamic Function() body, {bool skip = false}) {
    final savedPath = _testPath;
    if (_testPath.isNotEmpty) _testPath += ' ';
    _testPath += label;
    if (_discovery) {
      _pending += 1;
      _knownTests.add(_testPath);
      env.pumpEventQueue().whenComplete(_checkDone);
    } else {
      _pending += 1;
      final currentTest = _testPath;
      Future(() {
        print('[$platforms] Skip test "$currentTest"');
        _checkDone();
      });
    }
    _testPath = savedPath;
  }

  void test(String label, dynamic Function() body, {bool skip = false}) {
    final savedPath = _testPath;
    if (_testPath.isNotEmpty) _testPath += ' ';
    _testPath += label;
    if (_discovery) {
      _pending += 1;
      _knownTests.add(_testPath);
      env.pumpEventQueue().whenComplete(_checkDone);
    } else {
      _pending += 1;
      final currentTest = _testPath;
      if (!skip &&
          (onlyTests.isEmpty ||
              onlyTests.any((t) => t.allMatches(currentTest).isNotEmpty))) {
        env.test(label, () async {
          try {
            if (_canceled) {
              print('[$platforms] Test "$currentTest" cancelled');
              testResults[currentTest] = TestResult.cancelled();
            } else {
              await Future.any([
                Future(() async {
                  await body();
                  testResults[currentTest] = TestResult.success();
                }),
                Future.delayed(
                  Duration(seconds: 27),
                  () => throw TestTimeOutException(
                      '[$platforms] Test "$currentTest" timed out'),
                )
              ]);
            }
          } catch (ex, st) {
            testResults[currentTest] = TestResult.error(ex, st);
            rethrow;
          } finally {
            _checkDone();
          }
        });
      } else {
        Future(() {
          print('[$platforms] Skip test "$currentTest"');
          _checkDone();
        });
      }
    }
    _testPath = savedPath;
  }

  void group(String label, dynamic Function() body, {bool skip = false}) {
    final savedPath = _testPath;
    if (_testPath.isNotEmpty) _testPath += ' ';
    _testPath += label;
    if (_discovery) {
      _knownGroups.add(_testPath);
      body();
    } else {
      if (!skip) {
        env.group(label, body);
      } else {
        print('[$platforms] Skip group "$label"');
      }
    }
    _testPath = savedPath;
  }

  static final _knownGroups = <String>{};

  static Iterable<String> get knownGroups => _knownGroups.where(
      (_) => true); // force iterable to avoid exposing the underlying list

  static Iterable<String> get rootGroups sync* {
    for (var group in _knownGroups) {
      if (_knownGroups.any((g) => g != group && group.startsWith(g))) {
        continue;
      }
      yield group;
    }
  }

  static final _knownTests = <String>{};

  static Iterable<String> get knownTests => _knownTests.where(
      (_) => true); // force iterable to avoid exposing the underlying list
}

abstract class TestException implements Exception {
  TestException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class TestCancelledException extends TestException {
  TestCancelledException([super.message = 'Cancelled']);
}

class TestTimeOutException extends TestException {
  TestTimeOutException([super.message = 'Timeout']);
}

class TestResult {
  TestResult._(this.success, this.error, this.stackTrace);

  TestResult.success() : this._(true, null, null);

  TestResult.cancelled() : this._(false, TestCancelledException(), null);

  TestResult.error(Object error, [StackTrace? stackTrace])
      : this._(false, error, stackTrace);

  final bool success;
  final Object? error;
  final StackTrace? stackTrace;
}
