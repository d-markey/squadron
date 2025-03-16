import '../../exceptions/exception_manager.dart';
import '../../exceptions/squadron_error.dart';
import '../../local_worker/local_worker.dart';
import '../../typedefs.dart';

/// Creates a [LocalWorker]
LocalWorker<W> createLocalWorker<W>(W service, OperationsMap operations,
        ExceptionManager exceptionManager) =>
    throw SquadronErrorImpl.create('Platform not supported');
