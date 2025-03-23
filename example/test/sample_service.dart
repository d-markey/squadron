import 'dart:async';

import 'package:squadron/squadron.dart';

import 'identity_service.dart';

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
    // io() is asynchronous --> log messages will be received separately because
    // of the "await" between both calls
    _logger.log(threadId, '[${DateTime.now()}] start io($milliseconds)...');
    await Future.delayed(Duration(milliseconds: milliseconds));
    _logger.log(threadId, '[${DateTime.now()}] done  io($milliseconds)...');
  }

  @override
  void cpu({required int milliseconds}) {
    // cpu() is synchronous --> both log messages will be received ~ at the same time
    _logger.log(threadId, '[${DateTime.now()}] start cpu($milliseconds)...');
    final sw = Stopwatch()..start();
    while (sw.elapsedMilliseconds < milliseconds) {/* cpu */}
    _logger.log(threadId, '[${DateTime.now()}] done  cpu($milliseconds)...');
    // log() is asynchronous, so previous calls were only registered to the
    // event loop, and cannot execute before this point
  }

  // command IDs --> command handlers
  @override
  late final operations = OperationsMap({
    SampleService.ioCommand: (WorkerRequest r) => io(milliseconds: r.args[0]),
    SampleService.cpuCommand: (WorkerRequest r) => cpu(milliseconds: r.args[0]),
  });
}
