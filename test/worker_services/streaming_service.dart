import 'dart:async';

import 'package:squadron/squadron.dart';

import 'delays.dart';

class StreamingService implements WorkerService {
  StreamingService() {
    operations.addAll({
      $getMonitored: (r) => getMonitored(),
      $monitoredStream: (r) => monitoredStream(),
    });
  }

  static const $getMonitored = 1;
  static const $monitoredStream = 2;

  @override
  final operations = <int, CommandHandler>{};

  int _monitored = 0;

  FutureOr<int> getMonitored() => _monitored;

  Stream<int> monitoredStream() {
    late final StreamController<int> controller;
    int pauses = 0;
    controller = StreamController<int>(
      onListen: () async {
        _monitored += 1;
        int i = 0;
        while (true) {
          if (pauses == 0) {
            i++;
            controller.add(i);
          }
          await Future.delayed(TestDelays.shortDelay);
        }
      },
      onPause: () {
        pauses += 1;
      },
      onResume: () {
        if (pauses > 0) pauses -= 1;
      },
      onCancel: () {
        _monitored -= 1;
        controller.close();
      },
    );

    return controller.stream;
  }
}
