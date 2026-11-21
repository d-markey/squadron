import 'package:squadron/squadron.dart';

import '../../worker_services/persons/person_service.dart';

const entryPoint = InProcEntryPoint(_start);

void _start(WorkerRequest command) {
  runWorkerService(
    (_) => PersonService(),
    command,
  );
}
