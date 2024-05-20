import '../../exceptions/exception_manager.dart';
import '../../exceptions/squadron_error.dart';
import '../../local_worker/local_worker.dart';
import '../../worker_service.dart';

/// Creates a [LocalWorker] on a native platform.
LocalWorker<W> createLocalWorker<W extends WorkerService>(
        W service, ExceptionManager exceptionManager) =>
    throw SquadronErrorExt.create('Platform not supported', StackTrace.current);
