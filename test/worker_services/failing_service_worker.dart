import 'package:squadron/squadron.dart';

import 'failing_service.dart';
import 'worker_entry_points.dart';

class FailingWorkerPool extends WorkerPool<FailingWorker>
    implements FailingService {
  FailingWorkerPool([ConcurrencySettings? concurrencySettings])
      : super(() => FailingWorker(),
            concurrencySettings:
                concurrencySettings ?? ConcurrencySettings.fourIoThreads);

  @override
  Future noop() => execute((w) => w.noop());
}

class FailingWorker extends Worker implements FailingService {
  FailingWorker._(dynamic entryPoint) : super(entryPoint);

  FailingWorker() : this._(EntryPoints.failing);

  static FailingWorker? missingCommand() =>
      (EntryPoints.failingWithMissingCommand == null)
          ? null
          : FailingWorker._(EntryPoints.failingWithMissingCommand);

  @override
  Future noop() => send(FailingService.noopCommand);
}
