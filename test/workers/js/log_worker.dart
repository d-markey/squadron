import 'package:squadron/squadron.dart';

import '../../worker_services/log_service.dart';

void main() {
  runWorkerService((_) => LogService());
}
