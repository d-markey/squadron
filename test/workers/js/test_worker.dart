import 'package:squadron/squadron.dart';

import '../../worker_services/test_service.dart';

void main() {
  run(
    (startReq) {
      final startUpMode = Squadron.converter.v<int>()(startReq.args[0]);
      switch (startUpMode) {
        case TestService.startupThrows:
          throw Exception('Intentional failure');
        case TestService.startupInvalid:
          return TestService(invalid: true);
        default:
          return TestService();
      }
    },
  );
}
