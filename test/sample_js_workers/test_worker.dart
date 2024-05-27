import 'package:squadron/squadron.dart';

import '../worker_services/test_service.dart';

void main() => run(
      (startRequest) {
        dbgTrace('test_worker service initialization');
        dbgTrace('   startRequest = $startRequest');
        dbgTrace('   startRequest.args[0] = ${startRequest.args[0]}');
        final startUpMode = (startRequest.args[0] as num).toInt();
        dbgTrace('   startUpMode = $startUpMode');
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
