import 'dart:async';

import 'package:test/test.dart' as env;

import '_test_context_stub.dart'
    if (dart.library.io) '../workers/vm/_test_context.dart'
    if (dart.library.html) '../workers/js/_test_context.dart'
    if (dart.library.js_interop) '../workers/wasm/_test_context.dart' as impl;
import 'test_entry_points.dart';
import 'test_platform.dart';

class TestContext {
  TestContext._(this.workerPlatform);

  static Future<TestContext> init(String root,
      [TestPlatform? workerPlatform]) async {
    workerPlatform ??= impl.platform;
    final testContext = TestContext._(workerPlatform);
    await testContext.entryPoints.set(root, workerPlatform);
    return testContext;
  }

  static const cancelled = '@@CANCELLED@@';
  static const finished = '@@DONE@@';

  Completer<void>? _completer;
  int _pending = 0;
  bool _canceled = false;

  int get pending => _pending;

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

  final TestPlatform workerPlatform;

  TestPlatform get clientPlatform => impl.platform;
  String get clientPlatformName => impl.platformName;

  final entryPoints = TestEntryPoints();

  final onlyTests = <Pattern>{};

  final testResults = <String, TestResult>{};

  String _testPath = '';

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
      final timeout = Timer(Duration(seconds: 30), () {
        _pending -= 1;
        if (_pending == 0 && _completer?.isCompleted == false) {
          _completer!.complete();
          _completer = null;
        }
      });
      env.test(label, () async {
        try {
          if (_canceled) {
            print('Test "$currentTest" cancelled');
            testResults[currentTest] = TestResult.cancelled();
          } else {
            final res = body();
            if (res is Future) {
              await res;
            }
            testResults[currentTest] = TestResult.success();
          }
        } catch (ex, st) {
          testResults[currentTest] = TestResult.error(ex, st);
          rethrow;
        } finally {
          timeout.cancel();
          _pending -= 1;
          if (_pending == 0 && _completer?.isCompleted == false) {
            _completer!.complete();
            _completer = null;
          }
        }
      });
    } else {
      // print('Ignored test: "$label"');
    }
    _testPath = savedPath;
  }

  void group(String label, dynamic Function() body) {
    final savedPath = _testPath;
    if (_testPath.isNotEmpty) _testPath += ' ';
    _testPath += label;
    if (!_knownGroups.contains(_testPath)) {
      print('Unregistered group $_testPath');
    }
    env.group(label, body);
    _testPath = savedPath;
  }

  static final _knownTests = <String>{
    '- WebWorker - classic Web Worker',
    '- WebWorker - native Web Worker',
    '- WebWorker - in-memory Web Worker',
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
    '- Squadron Worker - workloads - error handling - CustomException',
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
    '- WorkerPool - prime worker pool with cache',
    '- WorkerPool - worker pool monitoring',
    '- WorkerPool - initialization error - failed init',
    '- WorkerPool - initialization error - missing command',
    '- WorkerPool - initialization error - invalid command ID',
    '- WorkerPool - error handling - Exception',
    '- WorkerPool - error handling - WorkerException',
    '- WorkerPool - error handling - TaskTimeOutException',
    '- WorkerPool - error handling - CanceledException',
    '- WorkerPool - error handling - CustomException',
    '- WorkerPool - error handling - CustomException - after deserializer deregistation',
    '- WorkerPool - value - performance',
    '- WorkerPool - streaming - performance',
    '- WorkerPool - stopped pool will not accept new requests',
    '- WorkerPool - restarted pool will serve new requests',
    '- WorkerPool - pool termination does not prevent processing of pending tasks',
    '- WorkerPool - Streaming - with multiple errors - cancelOnError: false',
    '- WorkerPool - Streaming - with multiple errors - cancelOnError: true',
    '- WorkerPool - Streaming - with multiple errors - await for',
    '- WorkerPool - Streaming - with multiple errors - throwing in await for',
    '- WorkerPool - Streaming - with multiple errors - pause/resume',
    '- WorkerPool - Streaming - with multiple errors - pause/resume/cancel - using a StreamTask',
    '- WorkerPool - Streaming - with multiple errors - immediate cancelation',
    '- LocalWorker - Identity - LocalWorker',
    '- LocalWorker - Identity - Squadron Worker',
    '- LocalWorker - Identity - WorkerPool',
    '- LocalWorker - Exception - LocalWorker',
    '- LocalWorker - Exception - Squadron Worker',
    '- LocalWorker - Exception - WorkerPool',
    '- LocalWorker - Stream - LocalWorker',
    '- LocalWorker - Stream - Squadron Worker',
    '- LocalWorker - Stream - WorkerPool',
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
    '- Cancelation - TimeoutToken - finite() worker',
    '- Cancelation - TimeoutToken - infinite() worker',
    '- Cancelation - TimeoutToken - finite() pool',
    '- Cancelation - CompositeToken - finite() worker',
    '- Cancelation - CompositeToken - infinite() worker',
    '- Cancelation - CompositeToken - finite() pool',
    '- GitHub Issues - #8 - Exceptions from Streams must come through onError - Squadron Worker',
    '- GitHub Issues - #8 - Exceptions from Streams must come through onError - Worker Pool',
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
    '- WorkerPool',
    '- WorkerPool - initialization error',
    '- WorkerPool - error handling',
    '- WorkerPool - Streaming',
    '- LocalWorker',
    '- LocalWorker - Identity',
    '- LocalWorker - Exception',
    '- LocalWorker - Stream',
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

class TestCancelledException implements Exception {}

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
