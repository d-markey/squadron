import 'dart:async';

import 'worker_request.dart';
import 'worker_service.dart';

import 'bootstrapper_stub.dart'
    if (dart.library.js) 'browser/bootstrapper.dart'
    if (dart.library.html) 'browser/bootstrapper.dart'
    if (dart.library.io) 'native/bootstrapper.dart';

typedef WorkerInitializer = FutureOr<WorkerService> Function(WorkerRequest startRequest);

FutureOr run(WorkerInitializer initializer, Map command) =>
  bootstrap(initializer, command);
