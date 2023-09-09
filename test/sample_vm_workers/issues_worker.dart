import 'package:squadron/squadron.dart';

import '../worker_services/issues_service.dart';

void start(List command) => run((startRequest) => IssuesService(), command);
