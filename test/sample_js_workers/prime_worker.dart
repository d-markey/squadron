import 'package:squadron/squadron.dart';

import '../worker_services/cache_service.dart';
import '../worker_services/prime_service.dart';

void main() =>
    run((startRequest) => PrimeService(CacheClient.connect(Channel.deserialize(
        startRequest.args.isEmpty ? null : startRequest.args[0]))));
