import 'package:squadron/squadron_service.dart';
import 'package:squadron/squadron_worker.dart' show Channel;

import '../worker_services/local_client_worker.dart';
import '../worker_services/local_workers/local_client.dart';

void start(List command) => run((startRequest) {
      final localClient =
          LocalClient(Channel.deserialize(startRequest.args[0])!);
      return LocalClientServiceImpl(localClient);
    }, command);
