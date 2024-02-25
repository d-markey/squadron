import 'dart:isolate';

import '../../../squadron.dart';
import '../xplat/_worker_runner.dart';
import '_worker_runner.dart';

void bootstrap(WorkerInitializer initializer, WorkerRequest? command) async {
  final workerPort = ReceivePort();

  final runner = WorkerRunner((r) {
    r.logger.t('terminating Isolate');
    workerPort.close();
    Isolate.current.kill();
  });

  workerPort.listen(runner.handle);
  await runner.connect(command, workerPort.sendPort, initializer);
}
