import 'dart:async';
import 'dart:math';

import 'package:squadron/squadron.dart';

class PiDigitsWorker extends Worker implements PiDigitsService {
  PiDigitsWorker(dynamic entryPoint, {String? id, List args = const []})
      : super(entryPoint, id: id, args: args);

  @override
  Future<int> getNth(int n) =>
      send(PiDigitsService.getNthCommand, [n]);

  @override
  Stream<int> getNDigits(int start, int n) =>
      stream(PiDigitsService.getNDigitsCommand, [start, n]);

  @override
  final Map<int, CommandHandler> operations = const {};
}

class PiDigitsService implements WorkerService {
  // see https://dept-info.labri.fr/~denis/Enseignement/2017-PG306/TP01/pi.java

  Stream<int> getNDigits(int start, int n) async* {
    final end = start + n;
    for (var i = start; i < end; i++) {
      yield await getNth(i);
    }
  }

  FutureOr<int> getNth(int n) {
    if (n < 0) return -1;
    n -= 1;
    double x =
        4 * piTerm(1, n) - 2 * piTerm(4, n) - piTerm(5, n) - piTerm(6, n);
    x = x - x.floor();
    return (x * 16).toInt();
  }

  static double piTerm(int j, int n) {
    // Calculate the left sum
    double s = 0;
    int r = j;
    for (int k = 0; k <= n; ++k) {
      s += powMod(16, n - k, r) / r;
      s = s - s.floor();
      r += 8;
    }
    // Calculate the right sum
    double t = 0;
    int k = n + 1;
    // Keep iterating until t converges (stops changing)
    r = 8 * k + j;
    while (true) {
      double newt = t + pow(16, n - k) / r;
      if (t == newt) {
        break;
      } else {
        t = newt;
      }
      k++;
      r += 8;
    }
    return s + t;
  }

  static int powMod(int a, int b, int m) {
    int tempo;
    if (b == 0) {
      tempo = 1;
    } else if (b == 1) {
      tempo = a;
    } else {
      int temp = powMod(a, b ~/ 2, m);
      if (b % 2 == 0) {
        tempo = (temp * temp) % m;
      } else {
        tempo = ((temp * temp) % m) * a % m;
      }
    }
    return tempo;
  }

  static const getNthCommand = 1;
  static const getNDigitsCommand = 2;

  @override
  late final Map<int, CommandHandler> operations = {
    PiDigitsService.getNthCommand: (r) => getNth(r.args[0]),
    PiDigitsService.getNDigitsCommand: (r) => getNDigits(r.args[0], r.args[1]),
  };
}
