import 'dart:async';

import 'package:squadron/squadron.dart';
import 'package:test/test.dart' as env;

import '_test_context_stub.dart'
    if (dart.library.io) '../workers/vm/_test_context.dart'
    if (dart.library.html) '../workers/js/_test_context.dart'
    if (dart.library.js_interop) '../workers/wasm/_test_context.dart' as impl;
import 'test_entry_points.dart';

class TestContext {
  TestContext._(this.workerPlatform) {
    platformConverter =
        useNumConverter ? NumConverter.instance : CastConverter.instance;
  }

  bool get hasImageCodecs => impl.hasImageCodecs;

  bool get hasChromiumBreakIterators => impl.hasChromiumBreakIterators;

  bool get supportsWasmGC => impl.supportsWasmGc;

  bool get isCrossOriginIsolated => impl.isCrossOriginIsolated;

  bool get useNumConverter => workerPlatform.isWasm || clientPlatform.isWasm;

  static Future<TestContext?> init(String root,
      [TestPlatform? workerPlatform]) async {
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
  static const finished = '@@DONE@@';

  Completer<void>? _completer;
  int _pending = 0;
  bool _canceled = false;

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
      '${workerPlatform.label} workers / ${clientPlatform.label} test client',
      testSuite,
    );
  }

  TestPlatform get clientPlatform => impl.platform;
  String get clientPlatformName =>
      '${impl.platformName} (${clientPlatform.label})';

  final TestPlatform workerPlatform;
  String get workerPlatformName =>
      '${impl.platformName} (${workerPlatform.label})';

  final entryPoints = TestEntryPoints();

  final onlyTests = <Pattern>{};

  final testResults = <String, TestResult>{};

  String _testPath = '';

  void skip(String label, dynamic Function() body, {bool skip = false}) {
    final savedPath = _testPath;
    if (_testPath.isNotEmpty) _testPath += ' ';
    _testPath += label;
    if (!_knownTests.contains(_testPath)) {
      print('Unregistered test $_testPath');
    }
    print('Skip test $_testPath');
    _testPath = savedPath;
  }

  void test(String label, dynamic Function() body, {bool skip = false}) {
    final savedPath = _testPath;
    if (_testPath.isNotEmpty) _testPath += ' ';
    _testPath += label;
    if (!_knownTests.contains(_testPath)) {
      print('Unregistered test $_testPath');
    }
    if (!skip &&
        (onlyTests.isEmpty ||
            onlyTests.any((t) => t.allMatches(_testPath).isNotEmpty))) {
      _pending += 1;
      final currentTest = _testPath;
      env.test(label, () async {
        try {
          if (_canceled) {
            print('Test "$currentTest" cancelled');
            testResults[currentTest] = TestResult.cancelled();
          } else {
            await Future.any([
              body(),
              Future.delayed(Duration(seconds: 27), () {
                throw TestCancelledException('Test timed out');
              })
            ].whereType<Future>());
            testResults[currentTest] = TestResult.success();
          }
        } on TestCancelledException catch (ex, st) {
          testResults[currentTest] = TestResult.error(ex, st);
          print(ex.message);
        } catch (ex, st) {
          testResults[currentTest] = TestResult.error(ex, st);
          rethrow;
        } finally {
          _checkDone();
        }
      });
    } else {
      // print('Ignored test: "$label"');
    }
    _testPath = savedPath;
  }

  void group(String label, dynamic Function() body, {bool skip = false}) {
    final savedPath = _testPath;
    if (_testPath.isNotEmpty) _testPath += ' ';
    _testPath += label;
    if (!_knownGroups.contains(_testPath)) {
      print('Unregistered group $_testPath');
    }
    if (!skip) {
      env.group(label, body);
    } else {
      // print('Ignored test: "$label"');
    }
    _testPath = savedPath;
  }

  static final _knownTests = <String>{
    '- WebWorker - plain Web Worker',
    '- WebWorker - plain Web Worker (in-memory)',
    '- WebWorker - regular Web Worker',
    '- WebWorker - missing Web Worker (JavaScript)',
    '- WebWorker - missing Web Worker (WebAssembly)',
    '- Squadron Worker - start/stop - start & stop',
    '- Squadron Worker - start/stop - hook',
    '- Squadron Worker - start/stop - hook failure',
    '- Squadron Worker - start/stop - install - no error',
    '- Squadron Worker - start/stop - install - error on installation',
    '- Squadron Worker - start/stop - install - error on uninstallation',
    '- Squadron Worker - start/stop - cannot restart after stop',
    '- Squadron Worker - workloads - sequential',
    '- Squadron Worker - workloads - parallel',
    '- Squadron Worker - workloads - error handling - Exception',
    '- Squadron Worker - workloads - error handling - WorkerException',
    '- Squadron Worker - workloads - error handling - TaskTimeOutException',
    '- Squadron Worker - workloads - error handling - CanceledException',
    '- Squadron Worker - workloads - error handling - CustomException (unregistered)',
    '- Squadron Worker - workloads - error handling - CustomException (registered)',
    '- Squadron Worker - workloads - error handling - invalid request',
    '- Squadron Worker - workloads - error handling - invalid response',
    '- Squadron Worker - workloads - error handling - missing operation',
    '- Squadron Worker - initialization error - not found',
    '- Squadron Worker - initialization error - failed init',
    '- Squadron Worker - initialization error - missing start request',
    '- Squadron Worker - initialization error - invalid command ID',
    '- Squadron Worker - streaming - cancelOnError: false',
    '- Squadron Worker - streaming - cancelOnError: true',
    '- Squadron Worker - streaming - await for',
    '- Squadron Worker - streaming - throwing in await for',
    '- Squadron Worker - streaming - pause/resume',
    '- Squadron Worker - streaming - immediate cancelation',
    '- Squadron Worker - streaming - subscription cancelation',
    '- Shared Channel - cache worker',
    '- Shared Channel - prime worker with cache',
    '- Worker Pool - prime worker pool with cache',
    '- Worker Pool - worker pool monitoring',
    '- Worker Pool - initialization error - failed init',
    '- Worker Pool - initialization error - missing command',
    '- Worker Pool - initialization error - invalid command ID',
    '- Worker Pool - error handling - Exception',
    '- Worker Pool - error handling - WorkerException',
    '- Worker Pool - error handling - TaskTimeOutException',
    '- Worker Pool - error handling - CanceledException',
    '- Worker Pool - error handling - CustomException (unregistered)',
    '- Worker Pool - error handling - CustomException (registered)',
    '- Worker Pool - performance - value',
    '- Worker Pool - performance - streaming',
    '- Worker Pool - stopped pool will not accept new requests',
    '- Worker Pool - restarted pool will serve new requests',
    '- Worker Pool - pool termination does not prevent processing of pending tasks',
    '- Worker Pool - streaming - with multiple errors - cancelOnError: false',
    '- Worker Pool - streaming - with multiple errors - cancelOnError: true',
    '- Worker Pool - streaming - with multiple errors - await for',
    '- Worker Pool - streaming - with multiple errors - throwing in await for',
    '- Worker Pool - streaming - with multiple errors - pause/resume',
    '- Worker Pool - streaming - with multiple errors - pause/resume/cancel - using a StreamTask',
    '- Worker Pool - streaming - with multiple errors - immediate cancelation',
    '- Local Worker - Identity - Local',
    '- Local Worker - Identity - Squadron',
    '- Local Worker - Identity - Pool',
    '- Local Worker - Exception - Local',
    '- Local Worker - Exception - Squadron',
    '- Local Worker - Exception - Pool',
    '- Local Worker - Stream - Local',
    '- Local Worker - Stream - Squadron',
    '- Local Worker - Stream - Pool',
    '- Logging off',
    '- Logging >= fatal',
    '- Logging >= error',
    '- Logging >= warning',
    '- Logging >= info',
    '- Logging >= debug',
    '- Logging >= trace',
    '- Logging all',
    '- Marshaler - unmarshaled "non-native" types work in VM, fail on Web',
    '- Marshaler - unmarshaled "non-native" input types work in VM, fail on Web',
    '- Marshaler - unmarshaled "non-native" output types work in VM, fail on Web',
    '- Marshaler - marshaled "non-native" types always work',
    '- Cancelation - ValueTask - immediate with pool.cancel()',
    '- Cancelation - ValueTask - immediate with pool.cancel(task)',
    '- Cancelation - ValueTask - immediate with task.cancel()',
    '- Cancelation - ValueTask - with pool.cancel()',
    '- Cancelation - ValueTask - with pool.cancel(task)',
    '- Cancelation - ValueTask - with task.cancel()',
    '- Cancelation - StreamTask - immediate with pool.cancel()',
    '- Cancelation - StreamTask - immediate with pool.cancel(task)',
    '- Cancelation - StreamTask - immediate with task.cancel()',
    '- Cancelation - StreamTask - with pool.cancel()',
    '- Cancelation - StreamTask - with pool.cancel(task)',
    '- Cancelation - StreamTask - with task.cancel()',
    '- Cancelation - CancelationToken - finite() worker',
    '- Cancelation - CancelationToken - infinite() worker',
    '- Cancelation - CancelationToken - finite() pool',
    '- Cancelation - CancelationToken - infinite() pool',
    '- Cancelation - TimeoutToken - finite() worker',
    '- Cancelation - TimeoutToken - infinite() worker',
    '- Cancelation - TimeoutToken - finite() pool',
    '- Cancelation - TimeoutToken - infinite() pool',
    '- Cancelation - CompositeToken - finite() worker',
    '- Cancelation - CompositeToken - infinite() worker',
    '- Cancelation - CompositeToken - finite() pool',
    '- Cancelation - CompositeToken - infinite() pool',
    '- GitHub Issues - #8 - Exceptions from Streams must come through onError - Squadron Worker',
    '- GitHub Issues - #8 - Exceptions from Streams must come through onError - Worker Pool',
    '- Not a worker (native platform)',
    '- Not a worker (Web platforms)',
  };

  static final _knownGroups = <String>{
    '- WebWorker',
    '- Squadron Worker',
    '- Squadron Worker - start/stop',
    '- Squadron Worker - start/stop - install',
    '- Squadron Worker - workloads',
    '- Squadron Worker - workloads - error handling',
    '- Squadron Worker - initialization error',
    '- Squadron Worker - streaming',
    '- Shared Channel',
    '- Worker Pool',
    '- Worker Pool - initialization error',
    '- Worker Pool - error handling',
    '- Worker Pool - performance',
    '- Worker Pool - streaming - with multiple errors',
    '- Local Worker',
    '- Local Worker - Identity',
    '- Local Worker - Exception',
    '- Local Worker - Stream',
    '- Logging',
    '- Marshaler',
    '- Cancelation',
    '- Cancelation - ValueTask',
    '- Cancelation - StreamTask',
    '- Cancelation - CancelationToken',
    '- Cancelation - TimeoutToken',
    '- Cancelation - CompositeToken',
    '- GitHub Issues',
    '- GitHub Issues - #8 - Exceptions from Streams must come through onError',
  };

  static Iterable<String> get rootGroups sync* {
    for (var group in _knownGroups) {
      if (_knownGroups.any((g) => g != group && group.startsWith(g))) {
        continue;
      }
      yield group;
    }
  }
}

class TestCancelledException implements Exception {
  TestCancelledException([this.message = 'Cancelled']);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
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

enum TestPlatform {
  unknown('Unknown'),
  vm('Native'),
  js('JavaScript'),
  wasm('WebAssembly');

  const TestPlatform(this.label);

  final String label;

  bool get isVm => this == vm;
  bool get isJs => this == js;
  bool get isWasm => this == wasm;
  bool get isWeb => isJs || isWasm;
}
