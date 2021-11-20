import 'package:squadron/squadron_service.dart';

import '../worker_services/sample_service.dart';

void start(Map command) => run((startRequest) => SampleService(), command);
