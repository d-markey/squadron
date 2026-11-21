import 'package:squadron/squadron.dart';

import '../../worker_services/log_service.dart';

final entryPoint = InProcEntryPoint(_start);

void _start(WorkerRequest command) {
  runWorkerService(
    (_) => LogService(),
    command,
  );
}
