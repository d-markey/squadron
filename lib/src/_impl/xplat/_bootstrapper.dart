import '../../exceptions/squadron_error.dart';
import '../../typedefs.dart';
import '../../worker/worker_request.dart';

void bootstrap(WorkerInitializer initializer, WorkerRequest? command) =>
    throw SquadronErrorImpl.create('Platform not supported');
