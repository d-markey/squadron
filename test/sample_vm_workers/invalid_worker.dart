import 'package:squadron/squadron_service.dart';

import '../worker_services/invalid_service.dart';

void start(Map command) => run((startRequest) => InvalidService(), command);
