import 'package:squadron/squadron.dart';

import '../../worker_services/local_client_worker.dart';
import '../../worker_services/local_workers/local_client.dart';

final entryPoint = InProcEntryPoint(_start);

void _start(WorkerRequest command) {
  runWorkerService(
    (startReq) {
      final channel = Channel.deserialize(startReq.args[0])!;
      final localClient = LocalClient(channel);
      return LocalClientServiceImpl(localClient);
    },
    command,
  );
}
