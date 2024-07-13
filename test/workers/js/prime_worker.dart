import 'package:squadron/squadron.dart';

import '../../worker_services/cache_service.dart';
import '../../worker_services/prime_service.dart';

void main() {
  print('PRIME SERVICE WORKER LOADED');
  run(
    (startRequest) {
      print('INITIALIZING PRIME SERVICE...');
      final logger = Logger();
      final cacheChannel = Channel.deserialize(
          startRequest.args.isEmpty ? null : startRequest.args[0], logger);
      print('   CACHE CHANNEL = $cacheChannel');
      final cacheClient = CacheClient.connect(cacheChannel);
      print('   CACHE CLIENT = $cacheClient');
      final service = PrimeService(cacheClient);
      print('   PRIME SERVICE READY');
      return service;
    },
  );
}
