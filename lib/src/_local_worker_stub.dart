import 'local_worker.dart' show LocalWorker;
import 'worker_service.dart';

/// Creates a [LocalWorker].
LocalWorker<W> createLocalWorker<W extends WorkerService>(W service) =>
    throw UnsupportedError(
        'LocalWorker.create() is not supported on this platform');
