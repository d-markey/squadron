import 'package:squadron/squadron.dart';

import '../../worker_services/local_client_worker.dart';
import '../../worker_services/local_workers/local_client.dart';
import '_platform.dart';

void start(WorkerRequest command) => run(
      (startReq) {
        setConverter(startReq);
        final channel = Channel.deserialize(startReq.args[1])!;
        final localClient = LocalClient(channel);
        return LocalClientServiceImpl(localClient);
      },
      command,
    );
