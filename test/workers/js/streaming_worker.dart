import 'package:squadron/squadron.dart';

import '../../worker_services/streaming_service.dart';

void main() {
  runWorkerService((_) => StreamingService());
}
