import 'dart:isolate';

import 'package:squadron/squadron.dart';

import '../worker_services/cache_service.dart';
import '../worker_services/prime_service.dart';

PrimeWorker createVmPrimeWorker([CacheWorker? cache]) =>
    PrimeWorker(_main, args: [cache?.channel?.share().serialize()]);

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
  final cacheEndPoint = startRequest.args.isEmpty
      ? null
      : Channel.deserialize(startRequest.args[0]);
  Cache? cache = (cacheEndPoint == null) ? null : CacheClient(cacheEndPoint);
  Worker.connect(startRequest.client, workerPort,
      operations: operations,
      serviceOperations: PrimeService(cache).operations);
}
