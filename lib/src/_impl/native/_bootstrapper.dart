import 'dart:isolate';

import '../../worker/worker_request.dart';
import '../../worker_service.dart';
import '../xplat/_worker_runner.dart';
import '_worker_runner.dart';

void bootstrap(WorkerInitializer initializer, WorkerRequest? command) {
  final workerPort = ReceivePort();

  final runner = WorkerRunner((r) {
    r.internalLogger.t('Terminating Isolate');
    workerPort.close();
    Isolate.current.kill(priority: Isolate.beforeNextEvent);
  });

  workerPort.listen(runner.handle);
  runner.connect(command, workerPort.sendPort, initializer);
}
