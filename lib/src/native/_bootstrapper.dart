import 'dart:isolate';

import '../xplat/_worker_monitor.dart';
import '../xplat/_worker_runner.dart';
import '../squadron.dart';
import '../worker_service.dart';

void bootstrap(WorkerInitializer initializer, Map? command) async {
  final workerPort = ReceivePort();
  final monitor = WorkerMonitor(() {
    Squadron.config('terminating Isolate');
    workerPort.close();
    Isolate.current.kill();
  });

  final runner = WorkerRunner(monitor);

  workerPort.listen((message) => runner.processMessage(message));

  await runner.connect(command, workerPort, initializer);
}
