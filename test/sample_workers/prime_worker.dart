import 'dart:isolate';
import 'dart:math';

import 'package:squadron/squadron.dart';

import 'cache_worker.dart';

class PrimeWorker extends Worker {
  PrimeWorker([CacheWorker? cache]) : super(PrimeWorker._main) {
    startArguments.add(cache?.workerPort);
  }

  @override
  final startArguments = [];

  Future<bool> isPrime(int number) {
    return send(_isPrime, [number]);
  }

  Stream<int> getPrimes(int min, int max) {
    assert(min <= max);
    return stream(_getPrimes, [min, max]);
  }

  static const primesTo1000 = <int>[
    2,
    3,
    5,
    7,
    11,
    13,
    17,
    19,
    23,
    29,
    31,
    37,
    41,
    43,
    47,
    53,
    59,
    61,
    67,
    71,
    73,
    79,
    83,
    89,
    97,
    101,
    103,
    107,
    109,
    113,
    127,
    131,
    137,
    139,
    149,
    151,
    157,
    163,
    167,
    173,
    179,
    181,
    191,
    193,
    197,
    199,
    211,
    223,
    227,
    229,
    233,
    239,
    241,
    251,
    257,
    263,
    269,
    271,
    277,
    281,
    283,
    293,
    307,
    311,
    313,
    317,
    331,
    337,
    347,
    349,
    353,
    359,
    367,
    373,
    379,
    383,
    389,
    397,
    401,
    409,
    419,
    421,
    431,
    433,
    439,
    443,
    449,
    457,
    461,
    463,
    467,
    479,
    487,
    491,
    499,
    503,
    509,
    521,
    523,
    541,
    547,
    557,
    563,
    569,
    571,
    577,
    587,
    593,
    599,
    601,
    607,
    613,
    617,
    619,
    631,
    641,
    643,
    647,
    653,
    659,
    661,
    673,
    677,
    683,
    691,
    701,
    709,
    719,
    727,
    733,
    739,
    743,
    751,
    757,
    761,
    769,
    773,
    787,
    797,
    809,
    811,
    821,
    823,
    827,
    829,
    839,
    853,
    857,
    859,
    863,
    877,
    881,
    883,
    887,
    907,
    911,
    919,
    929,
    937,
    941,
    947,
    953,
    967,
    971,
    977,
    983,
    991,
    997
  ];

  static const largePrimes = <int>[
    1000000007,
    1000000009,
    1000001789,
    1000001791,
    6643838879,
    99999199999,
    999999000001,
    67280421310721,
  ];

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
          req.exception(WorkerException('unknown message ${req.command}'),
              StackTrace.current);
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
    while (p <= max) {
      // p = 6 * k - 1
      if (_inRange(p)) yield p;
      p += 2; // p = 6 * k + 1
      if (_inRange(p)) yield p;
      p += 4; // p = 6 * (k+1) - 1
    }
  }
}
