import 'dart:isolate';
import 'dart:math';

import 'package:squadron/squadron.dart';

import 'cache_worker.dart';

class PrimeWorker extends Worker {
  PrimeWorker([ CacheWorker? cache ]) : super(PrimeWorker._main) {
    startArguments.add(cache?.commandPort);
  }

  @override
  final startArguments = [];

  Future<bool> isPrime(int number) {
    return send(_isPrime, [ number ]);
  }

  Stream<int> getPrimes(int min, int max) {
    assert(min <= max);
    return stream(_getPrimes, [ min, max ]);
  }

  // private implementation, this is the thread's main program
  static const _isPrime = 1;
  static const _getPrimes = 2;

  static void _main(List command) {
    final receiver = ReceivePort();
    final initReq = WorkerRequest.fromMessage(command);
    initReq.connect(receiver);

    Cache? cache;
    if (initReq.args[0] is SendPort) {
      cache = CacheClient(initReq.args[0]);
    }

    receiver.listen((command) async {
      final req = WorkerRequest.fromMessage(command);
      if (req.command == null) {
        receiver.close();
        return;
      }
      switch (req.command) {
        case _isPrime:
          req.reply(await _isPrimeNumber(req.args[0], cache));
          return;
        case _getPrimes:
          for (var p in _getPrimeCandidates(req.args[0], req.args[1])) {
            if (await _isPrimeNumber(p, cache)) req.reply(p);
          }
          req.endOfStream();
          return;
        default:
          req.exception(WorkerException('unknown message ${req.command}'), StackTrace.current);
          return;
      }
    });
  }

  static Future<bool> _isPrimeNumber(int n, Cache? cache) async {
    if (n == 2 || n == 3) return true;
    if (n < 2 || n % 2 == 0 || n % 3 == 0) return false;
    if (await cache?.containsKey(n) == true) return true;

    var max = sqrt(n).floor();
    for (var p in _getPrimeCandidates(5, max)) {
      if (n % p == 0) return false;
    }
    cache?.set(n, n);
    return true;
  }

  static Iterable<int> _getPrimeCandidates(int min, int max) sync* {
    bool _inRange(int p) => (min <= p && p <= max);

    // handle 2 and 3
    if (_inRange(2)) yield 2;
    if (_inRange(3)) yield 3;
    // all other primes are of the form (6 * k) +/- 1
    // start with k = (min + 1) ~/ 6
    var p = 6 * ((min + 1) ~/ 6) - 1;
    while (p <= max) {                    // p = 6 * k - 1
      if (_inRange(p)) yield p;
      p += 2;                             // p = 6 * k + 1
      if (_inRange(p)) yield p;           
      p += 4;                             // p = 6 * (k+1) - 1
    }
  }

}
