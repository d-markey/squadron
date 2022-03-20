import 'dart:html';

import '../_worker_runner.dart';
import '../squadron.dart';
import '../_worker_monitor.dart';
import '../worker_service.dart';

void bootstrap(WorkerInitializer initializer, Map? command) {
  final scope = DedicatedWorkerGlobalScope.instance;
  final operations = <int, CommandHandler>{};

  final com = MessageChannel();
  final monitor = WorkerMonitor(() {
    Squadron.config('terminating Web worker');
    com.port1.close();
    scope.close();
  });

  com.port1.onMessage.listen(
      (MessageEvent e) => WorkerRunner.process(operations, e.data, monitor));

  scope.onMessage.listen((MessageEvent e) =>
      WorkerRunner.connect(e.data, com.port2, operations, initializer));
}
