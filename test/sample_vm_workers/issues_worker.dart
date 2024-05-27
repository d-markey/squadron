import 'package:squadron/squadron.dart';

import '../worker_services/issues_service.dart';

void start(WorkerRequest command) =>
    run((startRequest) => IssuesService(), command);
