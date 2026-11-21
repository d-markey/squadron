import 'package:squadron/squadron.dart';

import 'job_service.dart';

const entryPoint = InProcEntryPoint(start);

void start(WorkerRequest command) =>
    runWorkerService((startRequest) => JobService(), command);
