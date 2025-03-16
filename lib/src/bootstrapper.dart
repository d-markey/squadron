import '_impl/xplat/_bootstrapper.dart'
    if (dart.library.io) '_impl/native/_bootstrapper.dart'
    if (dart.library.html) '_impl/web/_bootstrapper.dart'
    if (dart.library.js) '_impl/web/_bootstrapper.dart'
    if (dart.library.js_interop) '_impl/web/_bootstrapper.dart' as impl;
import 'typedefs.dart';
import 'worker/worker_request.dart';
import 'worker_service.dart';

/// Instantiates a [WorkerService] via the [initializer] and installs the service in a platform worker.
/// The [command] argument is ignored on Web platforms. On native platforms, the [command] argument *must
/// be* set to the [Isolate]'s startup parameter.
void run(WorkerInitializer initializer, [WorkerRequest? command]) =>
    impl.bootstrap(initializer, command);
