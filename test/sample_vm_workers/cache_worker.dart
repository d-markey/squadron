import 'package:squadron/squadron.dart';

import '../worker_services/cache_service.dart';

void start(List command) => run((startRequest) => CacheService(), command);
