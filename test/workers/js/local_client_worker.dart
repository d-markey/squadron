import 'package:squadron/squadron.dart';

import '../../worker_services/local_client_worker.dart';
import '../../worker_services/local_workers/local_client.dart';

void main() {
  run((startReq) {
    final channel = Channel.deserialize(startReq.args[0])!;
    final localClient = LocalClient(channel);
    return LocalClientServiceImpl(localClient);
  });
}
