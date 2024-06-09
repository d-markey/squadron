import 'package:squadron/squadron.dart';

import '../../worker_services/cache_service.dart';

void start(WorkerRequest command) =>
    run((startRequest) => CacheService(), command);
