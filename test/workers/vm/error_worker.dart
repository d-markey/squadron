import 'package:squadron/squadron.dart';

import '../../worker_services/error_service.dart';

final entryPoint = InProcEntryPoint(_start);

void _start(WorkerRequest command) {
  runWorkerService(
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

final entryPointWithMissingCommand = InProcEntryPoint(_startWithMissingCommand);

void _startWithMissingCommand(WorkerRequest command) {
  runWorkerService(
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
