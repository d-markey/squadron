import 'package:squadron/squadron.dart';

import 'job_service.dart';

void start(WorkerRequest command) =>
    run((startRequest) => JobService(), command);
