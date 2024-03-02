import 'dart:html';

import '../../worker_service.dart';
import '../xplat/_worker_runner.dart';
import '_worker_runner.dart';

void bootstrap(WorkerInitializer initializer, List? command) {
  final com = MessageChannel();

  final runner = WorkerRunner((r) {
    r.logger.t(() => 'terminating Web worker');
    com.port1.close();
    com.port2.close();
    DedicatedWorkerGlobalScope.instance.close();
  });

  com.port1.onMessage.listen(runner.handle);

  DedicatedWorkerGlobalScope.instance.onMessage.listen((event) {
    runner.connect(event.data, com.port2, initializer);
  });
}
