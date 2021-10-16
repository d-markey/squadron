import 'dart:async';

import 'package:squadron/squadron.dart';

class SampleWorker extends Worker implements SampleService {
  SampleWorker(dynamic entryPoint, {String? id, List args = const []})
      : super(entryPoint, id: id, args: args);

  @override
  Future io({required int milliseconds}) =>
      send(SampleService.ioCommand, [milliseconds]);

  @override
  Future cpu({required int milliseconds}) =>
      send(SampleService.cpuCommand, [milliseconds]);

  @override
  final Map<int, CommandHandler> operations = const {};
}

class SampleService {
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
  Map<int, CommandHandler> get operations => {
        ioCommand: (WorkerRequest r) => io(milliseconds: r.args[0]),
        cpuCommand: (WorkerRequest r) => cpu(milliseconds: r.args[0]),
      };
}