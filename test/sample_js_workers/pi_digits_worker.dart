import 'package:squadron/squadron_service.dart';

import '../worker_services/pi_digits_service.dart';

void main() {
  run((startRequest) => PiDigitsService(), const {});
}
