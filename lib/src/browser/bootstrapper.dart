import 'dart:async';
import 'dart:html';

import '../bootstrapper.dart' show WorkerInitializer;

import '../worker_request.dart';
import '../worker_service.dart';

FutureOr bootstrap(WorkerInitializer initializer, Map command) async {
  final scope = DedicatedWorkerGlobalScope.instance;
  final operations = <int, CommandHandler>{};

  final com = MessageChannel();
  com.port1.onMessage.listen((MessageEvent e) {
    final req = WorkerRequest.deserialize(e.data);
    if (req.terminate) {
      scope.close();
    } else {
      WorkerService.process(operations, req);
    }
  });

  scope.onMessage.listen((MessageEvent e) async {
    final startRequest = WorkerRequest.deserialize(e.data);
    assert(startRequest.connect == true);
    final service = await initializer(startRequest);
    WorkerService.connect(startRequest.client, com.port2,
        operations: operations, serviceOperations: service.operations);
  });
}
