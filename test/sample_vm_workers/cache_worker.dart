import 'dart:isolate';

import 'package:squadron/squadron.dart';

import '../worker_services/cache_service.dart';

CacheWorker createVmCacheWorker() => CacheWorker(_main);

void _main(Map command) {
  final operations = <int, CommandHandler>{};

  final workerPort = ReceivePort();
  workerPort.listen((command) {
    final req = WorkerRequest.deserialize(command);
    if (req.terminate) {
      Isolate.current.kill(priority: Isolate.immediate);
    } else {
      Worker.process(operations, req);
    }
  });

  final startRequest = WorkerRequest.deserialize(command);
  assert(startRequest.connect == true);
  Worker.connect(startRequest.client, workerPort,
      operations: operations, serviceOperations: CacheService().operations);
}
