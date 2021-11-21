import 'worker_service.dart';

import 'bootstrapper_stub.dart'
    if (dart.library.js) 'browser/bootstrapper.dart'
    if (dart.library.html) 'browser/bootstrapper.dart'
    if (dart.library.io) 'native/bootstrapper.dart';

/// Instantiates a [WorkerService] via the [initializer] and installs the service in a platform worker.
/// The [command] argument is ignored on Web platforms. On native platforms, the [command] argument must be
/// set to the [Isolate]'s startup parameter.
void run(WorkerInitializer initializer, [Map? command]) =>
    bootstrap(initializer, command);