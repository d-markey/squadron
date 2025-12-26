import 'dart:async';

import 'package:squadron/squadron.dart';

import 'clock.dart';

void main() async {
  final sw = Stopwatch()..start();

  void log(Object message) => print('[$threadId] [${sw.elapsed}] $message');

  final clock = ClockWorker(startWorker);

  await clock.start();

  log('Starting clock');

  clock.infiniteClock(periodInMs: 500).listen(
        (n) => log('Received $n from worker'),
        onError: (ex, st) => log(
            'Received error ${ex.runtimeType}: "${ex is SquadronException ? ex.message : ex.toString()}"'),
      );

  Future.delayed(Duration(seconds: 3), () {
    log('Killing worker');
    clock.terminate();
  });

  final timer = Timer.periodic(Duration(seconds: 1), (t) {
    final stats = clock.getStats();
    log('Clock status: ${stats.isStopped ? 'stopped' : 'running'}, up time = ${stats.upTime}, current workload = ${stats.workload}, total workload = ${stats.totalWorkload}');
  });

  await Future.delayed(const Duration(seconds: 10));

  timer.cancel();
  log('Terminating program');
}
