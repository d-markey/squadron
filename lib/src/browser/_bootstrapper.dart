import 'dart:html';

import '../squadron_logger.dart';
import '../xplat/_worker_monitor.dart';
import '../xplat/_worker_runner.dart';
import '../squadron.dart';
import '../worker_service.dart';

void bootstrap(
    WorkerInitializer initializer, List? command, SquadronLogger? logger) {
  final scope = DedicatedWorkerGlobalScope.instance;

  final com = MessageChannel();
  final monitor = WorkerMonitor(() {
    Squadron.config('terminating Web worker');
    com.port1.close();
    com.port2.close();
    scope.close();
  });

  Squadron.setLogger(logger);

  final runner = WorkerRunner(monitor);

  com.port1.onMessage.listen((event) => runner.processMessage(event.data));

  scope.onMessage
      .listen((event) => runner.connect(event.data, com.port2, initializer));
}
