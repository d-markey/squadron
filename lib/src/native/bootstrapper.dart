import 'dart:isolate';

import '../squadron.dart';
import '../worker_service.dart';

import '../_bootstrapper_stub.dart'
    show buildMessageProcessor, buildConnector, buildMonitor;

void bootstrap(WorkerInitializer initializer, Map? command) async {
  final operations = <int, CommandHandler>{};

  final workerPort = ReceivePort();
  final monitor = buildMonitor(() {
    Squadron.config('terminating Isolate');
    workerPort.close();
    Isolate.current.kill();
  });

  final process = buildMessageProcessor(operations, monitor);
  workerPort.listen((message) => process(message));

  final connect = buildConnector(workerPort, operations, initializer);
  await connect(command!);
}
