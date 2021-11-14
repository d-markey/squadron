import 'dart:async';

import 'package:squadron/squadron_service.dart';

class SampleService implements WorkerService {
  Future io({required int milliseconds}) =>
      Future.delayed(Duration(milliseconds: milliseconds));

  void cpu({required int milliseconds}) {
    final sw = Stopwatch()..start();
    while (sw.elapsedMilliseconds < milliseconds) {/* cpu */}
  }

  // command ids
  static const ioCommand = 1;
  static const cpuCommand = 2;

  // map of command ids to command handlers
  @override
  late final Map<int, CommandHandler> operations = {
    ioCommand: (WorkerRequest r) => io(milliseconds: r.args[0]),
    cpuCommand: (WorkerRequest r) => cpu(milliseconds: r.args[0]),
  };
}
