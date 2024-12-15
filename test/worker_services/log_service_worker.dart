import 'dart:async';

import 'package:squadron/squadron.dart';

import '../classes/test_context.dart';
import 'log_service.dart';

base class LogWorkerPool extends WorkerPool<LogWorker> implements LogService {
  LogWorkerPool(TestContext context)
      : super((ExceptionManager exceptionManager) => LogWorker(context));

  @override
  Future<void> setLevel(int level) => execute((w) => w.setLevel(level));

  @override
  Future<void> log() => execute((w) => w.log());
}

base class LogWorker extends Worker implements LogService {
  LogWorker(TestContext context) : super(context.entryPoints.log!);

  @override
  Future<void> setLevel(int level) =>
      send(LogService.setLevelCommand, args: [level]);

  @override
  Future<void> log() => send(LogService.logCommand);
}