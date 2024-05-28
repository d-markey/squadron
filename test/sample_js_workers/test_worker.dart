import 'package:squadron/squadron.dart';

import '../worker_services/test_service.dart';

void main() => run(
      (startRequest) {
        final startUpMode = (startRequest.args[0] as num).toInt();
        switch (startUpMode) {
          case TestService.startupThrows:
            throw Exception('Intentional failure');
          case TestService.startupInvalid:
            return TestService(invalid: true);
          case TestService.startupOk:
          default:
            return TestService();
        }
      },
    );
