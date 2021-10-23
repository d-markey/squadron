import 'dart:html';

import 'package:squadron/squadron.dart';

import '../../test/worker_services/cache_service.dart';
import '../../test/worker_services/prime_service.dart';

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
    final cacheEndPoint = startRequest.args.isEmpty
        ? null
        : Channel.deserialize(startRequest.args[0]);
    Cache? cache = (cacheEndPoint == null) ? null : CacheClient(cacheEndPoint);
    Worker.connect(startRequest.client, com.port2,
        operations: operations,
        serviceOperations: PrimeService(cache).operations);
  });
}
