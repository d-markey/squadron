import 'dart:async';
import 'dart:html';

class Logger {
  Logger(this.div) {
    _sw.start();
  }

  final Stopwatch _sw = Stopwatch();
  final DivElement div;

  void log(String message, {bool replaceLastLine = false}) {
    if (message.isNotEmpty) {
      message = '[${_sw.elapsed}] $message';
    }
    final lines = (div.innerHtml ?? '').split('<br>');
    if (lines.length == 1 && lines[0].isEmpty) {
      lines.clear();
    }
    if (replaceLastLine && lines.isNotEmpty) {
      lines[lines.length - 1] = message;
    } else {
      lines.add(message);
    }
    div.innerHtml = lines.join('<br>');
    div.scrollTo(0, 10000);
  }

  void clear() {
    div.innerHtml = '';
  }

  Future pause(String message, {required int seconds}) async {
    final waitTime = Duration(seconds: seconds);
    final timerPeriod = Duration(milliseconds: 100);
    final sw = Stopwatch();
    final timer = Timer.periodic(timerPeriod, (timer) {
      final remaining = Duration(
          microseconds: waitTime.inMicroseconds - sw.elapsedMicroseconds);
      log(message.replaceAll('@countdown', remaining.toString()),
          replaceLastLine: sw.isRunning);
      sw.start();
    });
    await Future.delayed(waitTime);
    timer.cancel();
  }
}
