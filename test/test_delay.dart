import 'package:squadron/squadron.dart';

abstract class TestDelay {
  static final tick = (Squadron.osType == SquadronOSType.windows)
      ? Duration(microseconds: 18500)
      : Duration(microseconds: 12875);

  static final resolution = (Squadron.osType == SquadronOSType.windows)
      ? Duration(microseconds: 15625)
      : Duration(microseconds: 10000);

  static Future<void> pause(
      {required int ticks, void Function()? callback}) async {
    final microSecs = tick.inMicroseconds * ticks;
    final resMicroSecs = resolution.inMicroseconds;
    final firstHalf = (microSecs % resMicroSecs) ~/ 2;

    final sw = Stopwatch()..start();

    // 1. Aggressive start (first half of alignment remainder)
    while (sw.elapsedMicroseconds < firstHalf) {
      await Future.delayed(Duration.zero);
    }

    // 2. Be nice to the event loop in segments of `resolution``
    while (microSecs - sw.elapsedMicroseconds > resMicroSecs) {
      await Future.delayed(resolution);
    }

    // 3. Aggressively control the remaining time (fine-tuning)
    while (sw.elapsedMicroseconds <= microSecs) {
      await Future.delayed(Duration.zero);
    }

    callback?.call();
  }
}
