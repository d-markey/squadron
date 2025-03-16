import 'dart:async';

import 'package:squadron/squadron.dart';

import '../test_constants.dart';
import 'squadron_version.dart';

class StreamingService with SquadronVersion implements WorkerService {
  static const $getMonitored = 1;
  static const $monitoredStream = 2;

  @override
  late final operations = OperationsMap({
    SquadronVersion.versionCommand: (r) => getVersion(),
    $getMonitored: (r) => getMonitored(),
    $monitoredStream: (r) => monitoredStream(),
  });

  int _monitored = 0;

  FutureOr<int> getMonitored() => _monitored;

  Stream<int> monitoredStream() {
    late final StreamController<int> controller;
    int pauses = 0;
    controller = StreamController<int>(
      onListen: () async {
        _monitored += 1;
        int i = 0;
        while (!controller.isClosed) {
          if (pauses == 0) {
            i++;
            controller.add(i);
          }
          await Future.delayed(delay_20ms);
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
