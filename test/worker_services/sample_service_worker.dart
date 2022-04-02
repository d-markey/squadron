import 'dart:async';

import 'package:squadron/squadron.dart';

import 'sample_service.dart';
import 'worker_entry_points.dart';

class SampleWorkerPool extends WorkerPool<SampleWorker>
    implements SampleService {
  SampleWorkerPool([ConcurrencySettings? concurrencySettings])
      : super(() => SampleWorker(),
            concurrencySettings:
                concurrencySettings ?? ConcurrencySettings.fourIoThreads);

  @override
  Future io({required int milliseconds}) =>
      execute((w) => w.io(milliseconds: milliseconds));

  @override
  Future cpu({required int milliseconds}) =>
      execute((w) => w.cpu(milliseconds: milliseconds));

  @override
  Future<int> delayedIdentity(int n) => execute((w) => w.delayedIdentity(n));

  @override
  Stream<int> finiteSequence(int count, [CancellationToken? token]) =>
      stream((w) => w.finiteSequence(count, token));

  @override
  Stream<int> infiniteSequence(CancellationToken token) =>
      stream((w) => w.infiniteSequence(token));

  @override
  Future infiniteCpu(CancellationToken token) =>
      execute((w) => w.infiniteCpu(token));

  ValueTask<int> delayedIdentityTask(int n) =>
      scheduleTask((w) => w.delayedIdentity(n));

  StreamTask<int> finiteSequenceTask(int n, [CancellationToken? token]) =>
      scheduleStream((w) => w.finiteSequence(n, token));
}

class SampleWorker extends Worker implements SampleService {
  SampleWorker() : super(EntryPoints.sample);

  @override
  Future io({required int milliseconds}) =>
      send(SampleService.ioCommand, [milliseconds]);

  @override
  Future cpu({required int milliseconds}) =>
      send(SampleService.cpuCommand, [milliseconds]);

  @override
  Future<int> delayedIdentity(int n) =>
      send(SampleService.delayedIdentityCommand, [n]);

  @override
  Stream<int> finiteSequence(int count, [CancellationToken? token]) =>
      stream(SampleService.finiteSequenceCommand, [count], token);

  @override
  Stream<int> infiniteSequence(CancellationToken token) =>
      stream(SampleService.infiniteSequenceCommand, [], token);

  @override
  Future infiniteCpu(CancellationToken token) =>
      send(SampleService.infiniteCpuCommand, [token], token);
}
