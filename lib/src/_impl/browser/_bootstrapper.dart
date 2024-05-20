import 'dart:html' as web;

import '../../worker_service.dart';
import '../xplat/_worker_runner.dart';
import '_worker_runner.dart';

void bootstrap(WorkerInitializer initializer, List? command) {
  final com = web.MessageChannel();

  final runner = WorkerRunner((r) {
    r.internalLogger.t(() => 'terminating Web worker');
    com.port1.close();
    com.port2.close();
    web.DedicatedWorkerGlobalScope.instance.close();
  });

  com.port1.onMessage.listen(runner.handle);

  web.DedicatedWorkerGlobalScope.instance.onMessage.listen((event) {
    runner.connect(event.data, com.port2, initializer);
  });
}
