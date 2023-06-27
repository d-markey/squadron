import 'dart:async';

import 'package:squadron/squadron.dart';

import 'test_service.dart';
import 'worker_entry_points.dart';

class TestWorkerPool extends WorkerPool<TestWorker> implements TestService {
  TestWorkerPool._(dynamic entryPoint, ConcurrencySettings? concurrencySettings)
      : super(entryPoint,
            concurrencySettings:
                concurrencySettings ?? ConcurrencySettings.fourIoThreads);

  TestWorkerPool([ConcurrencySettings? concurrencySettings])
      : this._(() => TestWorker(),
            concurrencySettings ?? ConcurrencySettings.fourIoThreads);

  TestWorkerPool.failedInit([ConcurrencySettings? concurrencySettings])
      : this._(() => TestWorker.failedInit(), concurrencySettings);

  static TestWorkerPool? missingStartRequest(
      [ConcurrencySettings? concurrencySettings]) {
    if (EntryPoints.missingStartRequest == null) return null;
    return TestWorkerPool._(
        () => TestWorker.missingStartRequest()!, concurrencySettings);
  }

  TestWorkerPool.invalidCommand([ConcurrencySettings? concurrencySettings])
      : this._(() => TestWorker.invalidCommand(), concurrencySettings);

  @override
  Future log() => execute((w) => w.log());

  @override
  Future io({required int ms}) => execute((w) => w.io(ms: ms));

  @override
  Future cpu({required int ms}) => execute((w) => w.cpu(ms: ms));

  @override
  Future<int> delayed(int n) => execute((w) => w.delayed(n));

  @override
  Future<int> throwException() => execute((w) => w.throwException());

  @override
  Future<int> throwWorkerException() =>
      execute((w) => w.throwWorkerException());

  @override
  Future<int> throwTaskTimeOutException() =>
      execute((w) => w.throwTaskTimeOutException());

  @override
  Future<int> throwCancelledException() =>
      execute((w) => w.throwCancelledException());

  @override
  Future<int> throwCustomException() =>
      execute((w) => w.throwCustomException());

  @override
  Future<dynamic> forward(dynamic data) => execute((w) => w.forward(data));

  @override
  Future missing() => execute((w) => w.missing());

  @override
  Future<dynamic> invalidResponse() => execute((w) => w.invalidResponse());

  @override
  Future<bool> ping() => execute((w) => w.ping());

  @override
  Stream<int> finite(int count, [CancellationToken? token]) =>
      stream((w) => w.finite(count, token));

  @override
  Stream<int> infinite([CancellationToken? token]) =>
      stream((w) => w.infinite(token));

  @override
  Stream<int> clock({int frequency = 1, CancellationToken? token}) =>
      stream((w) => w.clock(frequency: frequency, token: token));

  @override
  Future cancellableInfiniteCpu(CancellationToken token) =>
      execute((w) => w.cancellableInfiniteCpu(token));

  @override
  Future<int> getPendingInfiniteWithErrors() => (maxWorkers == 1)
      ? execute((w) => w.getPendingInfiniteWithErrors())
      : throw WorkerException(
          'getPendingInfiniteWithErrors() is not supported for worker pools with maxWorker != 1');

  @override
  Stream<int> infiniteWithErrors([CancellationToken? token]) =>
      stream((w) => w.infiniteWithErrors(token));

  ValueTask<int> delayedIdentityTask(int n) =>
      scheduleTask((w) => w.delayed(n));

  StreamTask<int> finiteTask(int n, [CancellationToken? token]) =>
      scheduleStream((w) => w.finite(n, token));

  StreamTask<int> infiniteWithErrorsTask([CancellationToken? token]) =>
      scheduleStream((w) => w.infiniteWithErrors(token));
}

class TestWorker extends Worker implements TestService {
  TestWorker._(dynamic entryPoint, [PlatformWorkerHook? hook])
      : super(entryPoint, platformWorkerHook: hook);

  TestWorker([PlatformWorkerHook? hook]) : this._(EntryPoints.test, hook);

  TestWorker.failedInit() : this._(EntryPoints.failedInit);

  TestWorker.invalidCommand() : this._(EntryPoints.invalidCommand);

  static TestWorker? missingStartRequest() {
    if (EntryPoints.missingStartRequest == null) return null;
    return TestWorker._(EntryPoints.missingStartRequest);
  }

  @override
  Future log() => send(TestService.logCommand);

  @override
  Future io({required int ms}) => send(TestService.ioCommand, args: [ms]);

  @override
  Future cpu({required int ms}) => send(TestService.cpuCommand, args: [ms]);

  @override
  Future<int> delayed(int n) => send(TestService.delayedCommand, args: [n]);

  @override
  Future<int> throwException() => send(TestService.throwExceptionCommand);

  @override
  Future<int> throwWorkerException() =>
      send(TestService.throwWorkerExceptionCommand);

  @override
  Future<int> throwTaskTimeOutException() =>
      send(TestService.throwTaskTimeOutExceptionCommand);

  @override
  Future<int> throwCancelledException() =>
      send(TestService.throwCancelledExceptionCommand);

  @override
  Future<int> throwCustomException() =>
      send(TestService.throwCustomExceptionCommand);

  @override
  Future<dynamic> forward(dynamic data) =>
      send(TestService.forwardCommand, args: [data]);

  @override
  Future missing() => send(TestService.missingCommand);

  @override
  Future<dynamic> invalidResponse() => send(TestService.invalidResponseCommand);

  @override
  Future<bool> ping() => send(TestService.pingCommand);

  @override
  Stream<int> finite(int count, [CancellationToken? token]) =>
      stream(TestService.finiteCommand, args: [count], token: token);

  @override
  Stream<int> infinite([CancellationToken? token]) =>
      stream(TestService.infiniteCommand, token: token);

  @override
  Stream<int> clock({int frequency = 1, CancellationToken? token}) =>
      stream(TestService.clockCommand, args: [frequency], token: token);

  @override
  Future cancellableInfiniteCpu(CancellationToken token) =>
      send(TestService.cancellableInfiniteCpuCommand, token: token);

  @override
  Future<int> getPendingInfiniteWithErrors() =>
      send(TestService.getPendingInfiniteWithErrorsCommand);

  @override
  Stream<int> infiniteWithErrors([CancellationToken? token]) =>
      stream(TestService.infiniteWithErrorsCommand, token: token);
}
