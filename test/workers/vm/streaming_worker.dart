import 'package:squadron/squadron.dart';

import '../../worker_services/streaming_service.dart';

final entryPoint = InProcEntryPoint(_start);

void _start(WorkerRequest command) {
  runWorkerService(
    (_) => StreamingService(),
    command,
  );
}
