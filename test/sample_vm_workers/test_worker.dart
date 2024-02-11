import 'package:squadron/squadron.dart';

import '../worker_services/test_service.dart';

void start(List command) => run(
      (startRequest) {
        switch (startRequest.args[0]) {
          case TestService.startupThrows:
            throw Exception('Intentional failure');
          case TestService.startupInvalid:
            return TestService(invalid: true);
          case TestService.startupOk:
          default:
            return TestService();
        }
      },
      command,
    );

// void startWithException(List command) => run(
//       (startRequest) => throw Exception('Intentional failure'),
//       command,
//     );

void startWithMissingCommand(List command) => run(
      (startRequest) => TestService(),
      /* intentionally missing command */
    );

// void startWithInvalidCommand(List command) => run(
//       (startRequest) => TestService(invalid: true),
//       command,
//     );
