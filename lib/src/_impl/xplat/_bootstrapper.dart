import '../../exceptions/squadron_error.dart';
import '../../worker_service.dart';

void bootstrap(WorkerInitializer initializer, List? command) =>
    throw SquadronErrorExt.create('Platform not supported', StackTrace.current);
