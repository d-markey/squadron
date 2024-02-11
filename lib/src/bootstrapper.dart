import '_impl/native/_bootstrapper.dart'
    if (dart.library.js) '_impl/browser/_bootstrapper.dart'
    if (dart.library.html) '_impl/browser/_bootstrapper.dart';
import 'logging/squadron_logger.dart';
import 'worker_service.dart';

/// Instantiates a [WorkerService] via the [initializer] and installs the service in a platform worker.
/// The [command] argument is ignored on Web platforms. On native platforms, the [command] argument *must
/// be* set to the [Isolate]'s startup parameter.
void run(WorkerInitializer initializer,
        [List? command, SquadronLogger? logger]) =>
    bootstrap(initializer, command, logger);
