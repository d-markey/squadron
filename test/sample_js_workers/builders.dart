import 'package:squadron/squadron.dart';

import '../worker_services/cache_service.dart';
import '../worker_services/prime_service.dart';
import '../worker_services/rogue_service.dart';
import '../worker_services/sample_service.dart';

Map<Type, Worker Function([dynamic arg])> get workerBuilders => {
      CacheWorker: ([dynamic arg]) =>
          CacheWorker('sample_js_workers/cache_worker.dart.js'),
      PrimeWorker: ([dynamic arg]) => PrimeWorker(
          'sample_js_workers/prime_worker.dart.js',
          args: [(arg as CacheWorker?)?.channel?.share().serialize()]),
      RogueWorker: ([dynamic arg]) =>
          RogueWorker('sample_js_workers/rogue_worker.dart.js'),
      SampleWorker: ([dynamic arg]) =>
          SampleWorker('sample_js_workers/sample_worker.dart.js'),
    };
