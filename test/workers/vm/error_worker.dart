import 'package:squadron/squadron.dart';

import '../../worker_services/error_service.dart';

void start(WorkerRequest command) {
  run(
    (startReq) {
      switch (startReq.args[0]) {
        case ErrorService.startupThrows:
          throw Exception('Intended failure');
        case ErrorService.startupInvalid:
          return ErrorService(invalid: true);
        default:
          return ErrorService();
      }
    },
    command,
  );
}

void startWithMissingCommand(WorkerRequest command) {
  run(
    (startReq) {
      switch (startReq.args[0]) {
        case ErrorService.startupThrows:
          throw Exception('Intended failure');
        case ErrorService.startupInvalid:
          return ErrorService(invalid: true);
        default:
          return ErrorService();
      }
    },
    /* intentionally missing command */
  );
}
