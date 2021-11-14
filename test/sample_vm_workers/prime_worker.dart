import 'package:squadron/squadron_service.dart';

import '../worker_services/cache_service.dart';
import '../worker_services/prime_service.dart';

void start(Map command) {
  run((startRequest) {
    final cacheEndPoint = startRequest.args.isEmpty
        ? null
        : Channel.deserialize(startRequest.args[0]);
    Cache? cache = (cacheEndPoint == null) ? null : CacheClient(cacheEndPoint);
    return PrimeService(cache);
  }, command);
}
