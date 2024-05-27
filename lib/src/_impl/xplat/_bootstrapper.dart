import '../../exceptions/squadron_error.dart';
import '../../worker/worker_request.dart';
import '../../worker_service.dart';

void bootstrap(WorkerInitializer initializer, WorkerRequest? command) =>
    throw SquadronErrorExt.create('Platform not supported', StackTrace.current);
