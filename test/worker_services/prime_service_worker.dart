import 'dart:async';

import 'package:squadron/squadron.dart';

import '../classes/test_context.dart';
import 'cache_service_worker.dart';
import 'prime_service.dart';

class PrimeWorkerPool extends WorkerPool<PrimeWorker> implements PrimeService {
  PrimeWorkerPool(TestContext context,
      [CacheWorker? cache,
      ConcurrencySettings concurrencySettings =
          ConcurrencySettings.threeCpuThreads])
      : super(() => PrimeWorker(context, cache),
            concurrencySettings: concurrencySettings);

  @override
  Future<bool> isPrime(int n, [PerfCounter? counter]) =>
      execute((w) async => w.isPrime(n), counter: counter);

  @override
  Stream<int> getPrimes(int min, int max, [PerfCounter? counter]) =>
      stream((w) => w.getPrimes(min, max), counter: counter);
}

class PrimeWorker extends Worker implements PrimeService {
  PrimeWorker(TestContext context, CacheWorker? cache)
      : super(context.entryPoints.prime!, args: [
          cache?.getSharedChannel()!.serialize(),
        ]);

  @override
  FutureOr<bool> isPrime(int n) => send(PrimeService.isPrimeCommand, args: [n])
      .then(Squadron.converter.value<bool>());

  @override
  Stream<int> getPrimes(int min, int max) =>
      stream(PrimeService.getPrimesCommand, args: [min, max])
          .map(Squadron.converter.value<int>());
}
