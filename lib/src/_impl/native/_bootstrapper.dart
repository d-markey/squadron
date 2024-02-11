import 'dart:isolate';

import '../../logging/squadron_logger.dart';
import '../../squadron.dart';
import '../../worker_service.dart';
import '../xplat/_worker_monitor.dart';
import '../xplat/_worker_runner.dart';
import '_worker_runner.dart';

void bootstrap(WorkerInitializer initializer, List? command,
    SquadronLogger? logger) async {
  Squadron.setLogger(logger);

  final workerPort = ReceivePort();

  final runner = WorkerRunner(WorkerMonitor(() {
    Squadron.config('terminating Isolate');
    workerPort.close();
    Isolate.current.kill();
  }));

  workerPort.listen(runner.handle);
  await runner.connect(command, workerPort, initializer);
}
