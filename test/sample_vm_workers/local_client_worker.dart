import 'package:logger/logger.dart';
import 'package:squadron/squadron.dart';

import '../worker_services/local_client_worker.dart';
import '../worker_services/local_workers/local_client.dart';

void start(List command) => run((startRequest) {
      final logger = Logger();
      final localClient =
          LocalClient(Channel.deserialize(startRequest.args[0], logger)!);
      return LocalClientServiceImpl(localClient);
    }, command);
