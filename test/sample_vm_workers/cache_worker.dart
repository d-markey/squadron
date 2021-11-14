import 'package:squadron/squadron_service.dart';

import '../worker_services/cache_service.dart';

void start(Map command) {
  run((startRequest) => CacheService(), command);
}
