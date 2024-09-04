import 'package:squadron/squadron.dart';

import '../../worker_services/test_service.dart';
import '_platform.dart';

void main() => run(
      (startReq) {
        setConverter(startReq);
        final startUpMode = platformConverter.v<int>()(startReq.args[1]);
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
