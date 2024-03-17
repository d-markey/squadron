import 'package:squadron/squadron.dart';

import '../worker_services/cache_service.dart';
import '../worker_services/prime_service.dart';

void start(List command) => run((startRequest) {
      final logger = Logger();
      final cacheChannel = Channel.deserialize(
          startRequest.args.isEmpty ? null : startRequest.args[0], logger);
      return PrimeService(CacheClient.connect(cacheChannel));
    }, command);
