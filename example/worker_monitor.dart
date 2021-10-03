import 'dart:async';

import 'package:squadron/squadron.dart';

class WorkerMonitor {
  WorkerMonitor(this._pool, int maxIdleInMilliseconds)
      : maxIdle = Duration(milliseconds: maxIdleInMilliseconds);

  final WorkerPool _pool;
  final Duration maxIdle;

  Timer? _timer;

  int get stopped => _stopped;
  int _stopped = 0;

  void start() {
    var ticks = Duration(microseconds: maxIdle.inMicroseconds ~/ 2);
    _timer?.cancel();
    _timer = Timer.periodic(ticks, (timer) {
      _stopped = _pool.stop((w) => !w.isStopped && w.idleTime > maxIdle);
    });
  }

  void stop() {
    _timer?.cancel();
  }
}
