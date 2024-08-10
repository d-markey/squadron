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
      execute((w) async => await w.isPrime(n), counter: counter);

  @override
  Stream<int> getPrimes(int min, int max, [PerfCounter? counter]) =>
      stream((w) => w.getPrimes(min, max), counter: counter).map(Cast.toInt);
}

class PrimeWorker extends Worker implements PrimeService {
  PrimeWorker(TestContext context, CacheWorker? cache)
      : super(context.entryPoints.prime!,
            args: [cache?.getSharedChannel()!.serialize()]);

  @override
  FutureOr<bool> isPrime(int n) =>
      send<bool>(PrimeService.isPrimeCommand, args: [n]);

  @override
  Stream<int> getPrimes(int min, int max) =>
      stream<int>(PrimeService.getPrimesCommand, args: [min, max])
          .map(Cast.toInt);
}
