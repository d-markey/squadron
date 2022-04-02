import 'package:squadron/squadron.dart';

import 'invalid_service.dart';
import 'worker_entry_points.dart';

class InvalidWorkerPool extends WorkerPool<InvalidWorker>
    implements InvalidService {
  InvalidWorkerPool([ConcurrencySettings? concurrencySettings])
      : super(() => InvalidWorker(),
            concurrencySettings:
                concurrencySettings ?? ConcurrencySettings.fourIoThreads);

  @override
  Future noop() => execute((w) => w.noop());
}

class InvalidWorker extends Worker implements InvalidService {
  InvalidWorker() : super(EntryPoints.invalid);

  @override
  Future noop() => send(InvalidService.noopCommand);
}
