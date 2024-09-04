import 'package:squadron/squadron.dart';

import '../../worker_services/cache_service.dart';
import '_platform.dart';

void start(WorkerRequest command) => run(
      (startReq) {
        setConverter(startReq);
        return CacheService();
      },
      command,
    );
