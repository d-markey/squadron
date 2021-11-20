import 'dart:html';

import '../worker_monitor.dart';
import '../worker_service.dart';

void bootstrap(WorkerInitializer initializer, Map? command) {
  final scope = DedicatedWorkerGlobalScope.instance;

  final operations = <int, CommandHandler>{};
  final monitor = WorkerMonitor(() => scope.close());

  final com = MessageChannel();
  com.port1.onMessage.listen(
      (MessageEvent e) => WorkerService.process(operations, e.data, monitor));

  scope.onMessage.listen((MessageEvent e) {
    WorkerService.connect(e.data, com.port2, operations, initializer);
  });
}
