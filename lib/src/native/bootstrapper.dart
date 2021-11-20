import 'dart:isolate';

import '../worker_monitor.dart';
import '../worker_service.dart';

void bootstrap(WorkerInitializer initializer, Map? command) async {
  final operations = <int, CommandHandler>{};
  final monitor =
      WorkerMonitor(() => Isolate.current.kill(priority: Isolate.immediate));

  final workerPort = ReceivePort();
  workerPort
      .listen((command) => WorkerService.process(operations, command, monitor));

  await WorkerService.connect(command, workerPort, operations, initializer);
}
