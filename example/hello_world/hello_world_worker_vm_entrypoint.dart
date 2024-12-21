import 'package:squadron/squadron.dart';

import 'hello_world_worker_service.dart';

/// Use squadron_builder to generate this code.
/// Manual implementation is discouraged.
///
/// See https://github.com/d-markey/squadron_builder/tree/main/example/hello_world
///
/// Initializes the HelloWorldWorkerService running in the worker thread.
void start(WorkerRequest command) => run(
      (_) => HelloWorldWorkerService(),
      command,
    );
