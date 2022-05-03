import 'package:squadron/squadron_local_worker.dart';

import '../worker_services/test_service.dart';

void main() => run((startRequest) => TestService());
