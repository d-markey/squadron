import 'package:squadron/squadron.dart';

import '../../worker_services/cache_service.dart';
import '../../worker_services/prime_service.dart';

void start(WorkerRequest command) => run(
      (startReq) {
        final channel = (startReq.args.length < 2) ? null : startReq.args[1];
        final cacheChannel = Channel.deserialize(channel);
        return PrimeService(CacheClient.connect(cacheChannel));
      },
      command,
    );
