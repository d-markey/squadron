import 'package:squadron/squadron.dart';

import '../../worker_services/cache_service.dart';

void main() {
  run((startRequest) {
    final service = CacheService();
    return service;
  });
}
