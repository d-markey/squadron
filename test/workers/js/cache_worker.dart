import 'package:squadron/squadron.dart';

import '../../worker_services/cache_service.dart';

void main() {
  print('CACHE SERVICE WORKER LOADED');
  run((startRequest) {
    print('INITIALIZING CACHE SERVICE...');
    final service = CacheService();
    print('   CACHE SERVICE READY');
    return service;
  });
}
