import 'package:squadron/squadron.dart';

import '../../worker_services/error_service.dart';

void main() {
  run(
    (startReq) {
      final startUpMode = Squadron.converter.value<int>()(startReq.args[0]);
      switch (startUpMode) {
        case ErrorService.startupThrows:
          throw Exception('Intentional failure');
        case ErrorService.startupInvalid:
          return ErrorService(invalid: true);
        default:
          return ErrorService();
      }
    },
  );
}
