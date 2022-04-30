import 'dart:async';

import 'package:squadron/squadron.dart';

import 'cache_service_worker.dart';
import 'prime_service.dart';
import 'worker_entry_points.dart';

class PrimeWorkerPool extends WorkerPool<PrimeWorker> implements PrimeService {
  PrimeWorkerPool(
      [CacheWorker? cache,
      ConcurrencySettings concurrencySettings =
          ConcurrencySettings.threeCpuThreads])
      : super(() => PrimeWorker(cache),
            concurrencySettings: concurrencySettings);

  @override
  Future<bool> isPrime(int n, [PerfCounter? counter]) =>
      execute((w) => w.isPrime(n), counter: counter);

  @override
  Stream<int> getPrimes(int min, int max, [PerfCounter? counter]) =>
      stream((w) => w.getPrimes(min, max), counter: counter);
}

class PrimeWorker extends Worker implements PrimeService {
  PrimeWorker([CacheWorker? cache])
      : super(EntryPoints.prime, args: [cache?.channel!.share().serialize()]);

  @override
  Future<bool> isPrime(int n) => send<bool>(PrimeService.isPrimeCommand, [n]);

  @override
  Stream<int> getPrimes(int min, int max) =>
      stream<int>(PrimeService.getPrimesCommand, [min, max]);
}
