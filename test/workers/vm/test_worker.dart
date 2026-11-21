import 'package:squadron/squadron.dart';

import '../../worker_services/test_service.dart';

final entryPoint = InProcEntryPoint(_start);

void _start(WorkerRequest command) {
  runWorkerService(
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

final entryPointWithMissingCommand = InProcEntryPoint(_startWithMissingCommand);

void _startWithMissingCommand(WorkerRequest command) {
  runWorkerService(
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
