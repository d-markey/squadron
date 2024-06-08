import 'dart:html' as web;

import '../../worker/worker_request.dart';
import '../../worker_service.dart';
import '../xplat/_worker_runner.dart';
import '_worker_runner.dart';

void bootstrap(WorkerInitializer initializer, WorkerRequest? command) {
  final com = web.MessageChannel();

  final runner = WorkerRunner((r) {
    r.internalLogger.t('terminating Web Worker');
    com.port1.close();
    com.port2.close();
    web.DedicatedWorkerGlobalScope.instance.close();
  });

  com.port1.onMessage.listen(runner.handle);

  web.DedicatedWorkerGlobalScope.instance.onMessage.listen((event) {
    final args = event.data as List?;
    final req = (args == null) ? null : WorkerRequest(args);
    runner.connect(req, com.port2, initializer);
  });

  web.DedicatedWorkerGlobalScope.instance.postMessage($ready);
}
