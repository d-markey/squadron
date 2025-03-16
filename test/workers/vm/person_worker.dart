import 'package:squadron/squadron.dart';

import '../../worker_services/persons/person_service.dart';

void start(WorkerRequest command) {
  run(
    (_) => PersonService(),
    command,
  );
}
