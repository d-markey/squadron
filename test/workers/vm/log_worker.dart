import 'package:squadron/squadron.dart';

import '../../worker_services/log_service.dart';

void start(WorkerRequest command) {
  run(
    (startReq) => LogService(),
    command,
  );
}
