import 'dart:async';

import 'package:squadron/squadron.dart';

import 'logging_service.dart';

abstract class SampleService {
  Future<void> io({required int milliseconds});
  FutureOr<void> cpu({required int milliseconds});

  // command IDs
  static const ioCommand = 1;
  static const cpuCommand = 2;
}

class SampleServiceImpl implements SampleService, WorkerService {
  SampleServiceImpl(this._logger) {
    _logger.log(threadId, '$this initialized');
  }

  final LoggingClient _logger;

  @override
  Future<void> io({required int milliseconds}) async {
    // io() is asynchronous
    _logger.log(threadId, '[${DateTime.now()}] start io($milliseconds)...');
    // the first call to log() will execute while awaiting the delayed future
    await Future.delayed(Duration(milliseconds: milliseconds));
    _logger.log(threadId, '[${DateTime.now()}] done  io($milliseconds)...');
    // the second call to log() will execute after returning from this method
  }

  @override
  void cpu({required int milliseconds}) {
    // cpu() is synchronous, log() is asynchronous
    _logger.log(threadId, '[${DateTime.now()}] start cpu($milliseconds)...');
    // the first call to log() cannot execute while the sync loop executes
    final sw = Stopwatch()..start();
    while (sw.elapsedMilliseconds < milliseconds) {/* cpu */}
    _logger.log(threadId, '[${DateTime.now()}] done  cpu($milliseconds)...');
    // the first and second call to log() will execute after returning from this method
  }

  // command IDs --> command handlers
  @override
  late final operations = OperationsMap({
    SampleService.ioCommand: (WorkerRequest r) => io(milliseconds: r.args[0]),
    SampleService.cpuCommand: (WorkerRequest r) => cpu(milliseconds: r.args[0]),
  });
}
