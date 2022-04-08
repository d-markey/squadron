import 'package:squadron/squadron_service.dart';

import '../worker_services/issues_service.dart';

void start(Map command) => run((startRequest) => IssuesService(), command);
