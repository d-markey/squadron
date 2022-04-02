import 'package:squadron/squadron_service.dart';

import '../worker_services/invalid_service.dart';

void main() => run((startRequest) => InvalidService());
