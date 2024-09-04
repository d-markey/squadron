import 'package:squadron/squadron.dart';

import '../../worker_services/cache_service.dart';
import '../../worker_services/prime_service.dart';
import '_platform.dart';

void main() {
  run(
    (startReq) {
      setConverter(startReq);
      final channel = (startReq.args.length >= 2) ? startReq.args[1] : null;
      final cacheChannel = Channel.deserialize(channel);
      final cacheClient = CacheClient.connect(cacheChannel);
      final service = PrimeService(cacheClient);
      return service;
    },
  );
}
