import 'dart:async';

import 'package:squadron/squadron.dart';

import 'prime_service.dart';

class PrimeWorkerPool extends WorkerPool<PrimeWorker> implements PrimeService {
  PrimeWorkerPool(dynamic entryPoint,
      [Channel? cacheChannel,
      ConcurrencySettings concurrencySettings =
          ConcurrencySettings.fourCpuThreads])
      : super(() => PrimeWorker(entryPoint, cacheChannel),
            concurrencySettings: concurrencySettings);

  @override
  Future<bool> isPrime(int n) => execute((w) => w.isPrime(n));

  @override
  Stream<int> getPrimes(int min, int max) =>
      stream((w) => w.getPrimes(min, max));
}

class PrimeWorker extends Worker implements PrimeService {
  PrimeWorker(dynamic entryPoint, [Channel? cacheChannel])
      : super(entryPoint, args: [cacheChannel?.share().serialize()]);

  @override
  Future<bool> isPrime(int n) => send<bool>(PrimeService.isPrimeCommand, [n]);

  @override
  Stream<int> getPrimes(int min, int max) =>
      stream<int>(PrimeService.getPrimesCommand, [min, max]);
}
