import 'package:squadron/squadron.dart';

import 'cache_worker.dart' as cache_isolate;
import 'prime_worker.dart' as prime_isolate;
import 'rogue_worker.dart' as rogue_isolate;
import 'sample_worker.dart' as sample_isolate;
import '../worker_services/cache_service.dart';
import '../worker_services/prime_service.dart';
import '../worker_services/rogue_service.dart';
import '../worker_services/sample_service.dart';

Map<Type, Worker Function([dynamic arg])> get workerBuilders => {
      CacheWorker: ([dynamic arg]) => CacheWorker(cache_isolate.start),
      PrimeWorker: ([dynamic arg]) => PrimeWorker(prime_isolate.start,
          args: [(arg as CacheWorker?)?.channel?.share().serialize()]),
      RogueWorker: ([dynamic arg]) => RogueWorker(rogue_isolate.start),
      SampleWorker: ([dynamic arg]) => SampleWorker(sample_isolate.start),
    };
