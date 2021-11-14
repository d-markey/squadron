import 'dart:async';
import 'dart:isolate';

import '../bootstrapper.dart' show WorkerInitializer;
import '../worker_request.dart';
import '../worker_service.dart';

FutureOr bootstrap(WorkerInitializer initializer, Map command) async {
  final operations = <int, CommandHandler>{};

  final workerPort = ReceivePort();
  workerPort.listen((command) {
    final req = WorkerRequest.deserialize(command);
    if (req.terminate) {
      Isolate.current.kill(priority: Isolate.immediate);
    } else {
      WorkerService.process(operations, req);
    }
  });

  final startRequest = WorkerRequest.deserialize(command);
  assert(startRequest.connect == true);
  final service = await initializer(startRequest);
  WorkerService.connect(startRequest.client, workerPort,
      operations: operations, serviceOperations: service.operations);
}
