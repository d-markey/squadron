import 'dart:html';

import 'package:squadron/squadron.dart';

import '../worker_services/rogue_service.dart';

RogueWorker createJsRogueWorker() => RogueWorker('rogue_worker.dart.js');

void main() {
  final scope = DedicatedWorkerGlobalScope.instance;
  final operations = <int, CommandHandler>{};

  final com = MessageChannel();
  com.port1.onMessage.listen((MessageEvent e) {
    final req = WorkerRequest.deserialize(e.data);
    if (req.terminate) {
      scope.close();
    } else {
      Worker.process(operations, req);
    }
  });

  scope.onMessage.listen((MessageEvent e) {
    final startRequest = WorkerRequest.deserialize(e.data);
    assert(startRequest.connect == true);
    Worker.connect(startRequest.client, com.port2,
        operations: operations, serviceOperations: RogueService().operations);
  });
}
