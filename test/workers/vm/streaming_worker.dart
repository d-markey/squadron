import 'package:squadron/squadron.dart';

import '../../worker_services/streaming_service.dart';

void start(WorkerRequest command) {
  run(
    (startReq) => StreamingService(),
    command,
  );
}
