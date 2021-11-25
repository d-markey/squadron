import 'dart:async';

import 'package:squadron/squadron.dart';

import 'sample_service.dart';

class SampleWorkerPool extends WorkerPool<SampleWorker>
    implements SampleService {
  SampleWorkerPool(dynamic entryPoint,
      [ConcurrencySettings? concurrencySettings])
      : super(() => SampleWorker(entryPoint),
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
  Stream<int> delayedSequence(int count) =>
      stream((w) => w.delayedSequence(count));

  @override
  Stream<int> cancellableSequence(
          bool handleCancellation, [CancellationToken? token]) =>
      stream((w) => w.cancellableSequence(handleCancellation, token), token: token);

  ValueTask<int> delayedIdentityTask(int n) =>
      scheduleTask((w) => w.delayedIdentity(n));

  StreamTask<int> delayedSequenceTask(int n) =>
      scheduleStream((w) => w.delayedSequence(n));
}

class SampleWorker extends Worker implements SampleService {
  SampleWorker(dynamic entryPoint) : super(entryPoint);

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
  Stream<int> delayedSequence(int count) =>
      stream(SampleService.delayedSequenceCommand, [count]);

  @override
  Stream<int> cancellableSequence(
          bool handleCancellation, [CancellationToken? token]) =>
      stream(SampleService.cancellableSequenceCommand, [handleCancellation],
          token);
}
