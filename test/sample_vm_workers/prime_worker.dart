import 'package:squadron/squadron_service.dart';
import 'package:squadron/squadron_worker.dart' show Channel;

import '../worker_services/cache_service.dart';
import '../worker_services/prime_service.dart';

void start(List command) => run(
    (startRequest) => PrimeService(CacheClient.connect(Channel.deserialize(
        startRequest.args.isEmpty ? null : startRequest.args[0]))),
    command);
