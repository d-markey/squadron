import 'package:squadron/squadron_service.dart';
import 'package:squadron/squadron_worker.dart' show Channel;

import '../../test/worker_services/cache_service.dart';
import '../../test/worker_services/prime_service.dart';

void main() =>
    run((startRequest) => PrimeService(CacheClient.connect(Channel.deserialize(
        startRequest.args.isEmpty ? null : startRequest.args[0]))));
