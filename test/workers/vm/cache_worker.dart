import 'package:squadron/squadron.dart';

import '../../worker_services/cache_service.dart';

final entryPoint = InProcEntryPoint(_start);

void _start(WorkerRequest command) {
  runWorkerService(
    (_) => CacheService(),
    command,
  );
}
