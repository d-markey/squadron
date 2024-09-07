import 'package:squadron/squadron.dart';

import '../../worker_services/cache_service.dart';
import '../../worker_services/prime_service.dart';

void start(WorkerRequest command) => run(
      (startReq) {
        final channel = startReq.args.isEmpty ? null : startReq.args[0];
        final cacheChannel = Channel.deserialize(channel);
        final cacheClient = CacheClient.connect(cacheChannel);
        return PrimeService(cacheClient);
      },
      command,
    );
