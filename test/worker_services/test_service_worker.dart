import 'dart:async';

import 'package:squadron/squadron.dart';

import 'test_service.dart';
import 'worker_entry_points.dart';

class TestWorkerPool extends WorkerPool<TestWorker> implements TestService {
  TestWorkerPool(
      [ConcurrencySettings? concurrencySettings, LocalSquadronLogger? logger])
      : super(() => TestWorker(logger),
            concurrencySettings:
                concurrencySettings ?? ConcurrencySettings.fourIoThreads);

  @override
  Future log() => execute((w) => w.log());

  @override
  Future io({required int milliseconds}) =>
      execute((w) => w.io(milliseconds: milliseconds));

  @override
  Future cpu({required int milliseconds}) =>
      execute((w) => w.cpu(milliseconds: milliseconds));

  @override
  Future<int> delayed(int n) => execute((w) => w.delayed(n));

  @override
  Stream<int> finite(int count, [CancellationToken? token]) =>
      stream((w) => w.finite(count, token));

  @override
  Stream<int> infinite(CancellationToken token) =>
      stream((w) => w.infinite(token));

  @override
  Future cancellableInfiniteCpu(CancellationToken token) =>
      execute((w) => w.cancellableInfiniteCpu(token));

  @override
  Future<bool> cannotListen(CancellationToken token) =>
      execute((w) => w.cannotListen(token));

  @override
  Stream<int> infiniteWithErrors(CancellationToken token) =>
      stream((w) => w.infiniteWithErrors(token));

  ValueTask<int> delayedIdentityTask(int n) =>
      scheduleTask((w) => w.delayed(n));

  StreamTask<int> finiteTask(int n, [CancellationToken? token]) =>
      scheduleStream((w) => w.finite(n, token));
}

class TestWorker extends Worker implements TestService {
  TestWorker([LocalSquadronLogger? logger])
      : super(EntryPoints.test, args: [logger?.connectionInfo]);

  @override
  Future log() => send(TestService.logCommand);

  @override
  Future io({required int milliseconds}) =>
      send(TestService.ioCommand, [milliseconds]);

  @override
  Future cpu({required int milliseconds}) =>
      send(TestService.cpuCommand, [milliseconds]);

  @override
  Future<int> delayed(int n) => send(TestService.delayedCommand, [n]);

  @override
  Stream<int> finite(int count, [CancellationToken? token]) =>
      stream(TestService.finiteCommand, [count], token);

  @override
  Stream<int> infinite(CancellationToken token) =>
      stream(TestService.infiniteCommand, [token.serialize()], token);

  @override
  Future cancellableInfiniteCpu(CancellationToken token) =>
      send(TestService.cancellableInfiniteCpuCommand, [], token);

  @override
  Future<bool> cannotListen(CancellationToken token) =>
      send(TestService.cannotListenCommand, [], token);

  @override
  Stream<int> infiniteWithErrors(CancellationToken token) =>
      stream(TestService.infiniteWithErrorsCommand, [], token);
}
