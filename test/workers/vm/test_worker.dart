import 'package:squadron/squadron.dart';

import '../../worker_services/test_service.dart';

void start(WorkerRequest command) => run(
      (startRequest) {
        switch (startRequest.args[0]) {
          case TestService.startupThrows:
            throw Exception('Intended failure');
          case TestService.startupInvalid:
            return TestService(invalid: true);
          case TestService.startupOk:
          default:
            return TestService();
        }
      },
      command,
    );

void startWithMissingCommand(WorkerRequest command) => run(
      (startRequest) {
        switch (startRequest.args[0]) {
          case TestService.startupThrows:
            throw Exception('Intended failure');
          case TestService.startupInvalid:
            return TestService(invalid: true);
          case TestService.startupOk:
          default:
            return TestService();
        }
      },
      /* intentionally missing command */
    );
