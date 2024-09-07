import 'package:squadron/squadron.dart';

import '../../worker_services/test_service.dart';

void start(WorkerRequest command) {
  run(
    (startReq) {
      switch (startReq.args[0]) {
        case TestService.startupThrows:
          throw Exception('Intended failure');
        case TestService.startupInvalid:
          return TestService(invalid: true);
        default:
          return TestService();
      }
    },
    command,
  );
}

void startWithMissingCommand(WorkerRequest command) {
  run(
    (startReq) {
      switch (startReq.args[0]) {
        case TestService.startupThrows:
          throw Exception('Intended failure');
        case TestService.startupInvalid:
          return TestService(invalid: true);
        default:
          return TestService();
      }
    },
    /* intentionally missing command */
  );
}
