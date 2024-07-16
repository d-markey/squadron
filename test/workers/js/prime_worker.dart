import 'package:squadron/squadron.dart';

import '../../worker_services/cache_service.dart';
import '../../worker_services/prime_service.dart';

void main() {
  run(
    (startRequest) {
      final logger = Logger();
      final cacheChannel = Channel.deserialize(
          startRequest.args.isEmpty ? null : startRequest.args[0], logger);
      final cacheClient = CacheClient.connect(cacheChannel);
      final service = PrimeService(cacheClient);
      return service;
    },
  );
}
