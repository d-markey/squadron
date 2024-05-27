import '_impl/xplat/_bootstrapper.dart'
    if (dart.library.io) '_impl/native/_bootstrapper.dart'
    if (dart.library.html) '_impl/browser/_bootstrapper.dart'
    if (dart.library.js_interop) '_impl/wasm/_bootstrapper.dart';
import 'worker/worker_request.dart';
import 'worker_service.dart';

/// Instantiates a [WorkerService] via the [initializer] and installs the service in a platform worker.
/// The [command] argument is ignored on Web platforms. On native platforms, the [command] argument *must
/// be* set to the [Isolate]'s startup parameter.
void run(WorkerInitializer initializer, [WorkerRequest? command]) =>
    bootstrap(initializer, command);
