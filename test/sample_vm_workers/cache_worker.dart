import 'package:squadron/squadron_service.dart';

import '../worker_services/cache_service.dart';

void start(List command) => run((startRequest) => CacheService(), command);
