import 'dart:html';

import '../squadron.dart';
import '../worker_service.dart';

import '../_bootstrapper_stub.dart'
    show buildMessageProcessor, buildConnector, buildMonitor;

void bootstrap(WorkerInitializer initializer, Map? command) {
  final scope = DedicatedWorkerGlobalScope.instance;
  final operations = <int, CommandHandler>{};

  final com = MessageChannel();
  final monitor = buildMonitor(() {
    Squadron.config('terminating Web worker');
    com.port1.close();
    com.port2.close();
    scope.close();
  });

  final process = buildMessageProcessor(operations, monitor);
  com.port1.onMessage.listen((event) => process(event.data));

  final connect = buildConnector(com.port2, operations, initializer);
  scope.onMessage.listen((event) => connect(event.data));
}
