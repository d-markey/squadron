import 'package:squadron/squadron.dart';

import 'clock.dart';

void main() async {
  final clock = ClockWorker(startWorker);

  await clock.start();

  try {
    print('[$threadId] Starting clock');
    final sub = clock.infiniteClock(periodInMs: 500).listen((n) {
      print('[$threadId] Received $n from worker');
    });
    Future.delayed(Duration(seconds: 3), () {
      print('[$threadId] Canceling subscription');
      sub.cancel();
    });
  } finally {
    clock.stop();
    print('Worker has been stopped');
  }
}
