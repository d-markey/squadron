import 'dart:isolate';

import '../_worker_runner.dart';
import '../squadron.dart';
import '../_worker_monitor.dart';
import '../worker_service.dart';

void bootstrap(WorkerInitializer initializer, Map? command) async {
  final operations = <int, CommandHandler>{};

  final workerPort = ReceivePort();
  final monitor = WorkerMonitor(() {
    Squadron.warning('terminating Isolate');
    workerPort.close();
    Isolate.current.kill();
  });

  workerPort
      .listen((command) => WorkerRunner.process(operations, command, monitor));

  await WorkerRunner.connect(command, workerPort, operations, initializer);
}
