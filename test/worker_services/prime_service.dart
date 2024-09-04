import 'dart:async';
import 'dart:math';

import 'package:squadron/squadron.dart';

import 'cache_service.dart';

class PrimeService implements WorkerService {
  PrimeService([Cache? cache]) : _primeChecker = _checkWith(cache);

  static FutureOr<bool> Function(int) _checkWith(Cache? cache) {
    if (cache == null) {
      return _isPrime;
    } else {
      return (int n) async {
        bool? res = await cache.get(n);
        if (res == true) return true;
        res = _isPrime(n);
        cache.set(n, res);
        return res;
      };
    }
  }

  final FutureOr<bool> Function(int n) _primeChecker;

  FutureOr<bool> isPrime(int n) => _primeChecker(n);

  Stream<int> getPrimes(int min, int max) async* {
    for (var n in _getPrimeCandidates(min, max)) {
      if (await isPrime(n)) {
        yield n;
      }
    }
  }

  static const isPrimeCommand = 1;
  static const getPrimesCommand = 2;

  @override
  late final Map<int, CommandHandler> operations = {
    isPrimeCommand: (r) => isPrime((r.args[0] as num).toInt()),
    getPrimesCommand: (r) =>
        getPrimes((r.args[0] as num).toInt(), (r.args[1] as num).toInt()),
  };

  static Iterable<int> _getPrimeCandidates(int min, int max) sync* {
    bool inRange(int p) => (min <= p && p <= max);

    // handle 2 and 3
    if (inRange(2)) yield 2;
    if (inRange(3)) yield 3;
    // all other primes are of the form (6 * k) +/- 1
    // start with k = (min + 1) ~/ 6
    var p = 6 * ((min + 1) ~/ 6) - 1;
    while (p <= max) {
      // p = 6 * k - 1
      if (inRange(p)) yield p;
      p += 2; // p = 6 * k + 1
      if (inRange(p)) yield p;
      p += 4; // p = 6 * (k+1) - 1
    }
  }

  static bool _isPrime(int n) {
    if (n == 2 || n == 3) return true;
    if (n < 2 || n % 2 == 0 || n % 3 == 0) return false;

    var max = sqrt(n).floor();
    for (var p in _getPrimeCandidates(5, max)) {
      if (n % p == 0) return false;
    }
    return true;
  }
}
