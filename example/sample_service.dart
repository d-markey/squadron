import 'dart:async';

import 'package:squadron/squadron_service.dart';

abstract class SampleService {
  FutureOr io({required int milliseconds});
  FutureOr cpu({required int milliseconds});

  // command ids
  static const ioCommand = 1;
  static const cpuCommand = 2;
}

class SampleServiceImpl implements SampleService, WorkerService {
  @override
  Future io({required int milliseconds}) =>
      Future.delayed(Duration(milliseconds: milliseconds));

  @override
  void cpu({required int milliseconds}) {
    final sw = Stopwatch()..start();
    while (sw.elapsedMilliseconds < milliseconds) {/* cpu */}
  }

  // map of command ids to command handlers
  @override
  late final Map<int, CommandHandler> operations = {
    SampleService.ioCommand: (WorkerRequest r) => io(milliseconds: r.args[0]),
    SampleService.cpuCommand: (WorkerRequest r) => cpu(milliseconds: r.args[0]),
  };
}
