import 'dart:isolate';

import '../squadron_logger.dart';
import '../xplat/_worker_monitor.dart';
import '../xplat/_worker_runner.dart';
import '../squadron.dart';
import '../worker_service.dart';

void bootstrap(
    WorkerInitializer initializer, Map? command, SquadronLogger? logger) async {
  final workerPort = ReceivePort();
  final monitor = WorkerMonitor(() {
    Squadron.config('terminating Isolate');
    workerPort.close();
    Isolate.current.kill();
  });

  Squadron.setLogger(logger);

  final runner = WorkerRunner(monitor);

  workerPort.listen((message) => runner.processMessage(message));

  await runner.connect(command, workerPort, initializer);
}
