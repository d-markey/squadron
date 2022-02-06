import 'package:squadron/squadron.dart';

import 'failing_service.dart';

class FailingWorkerPool extends WorkerPool<FailingWorker>
    implements FailingService {
  FailingWorkerPool(dynamic entryPoint,
      [ConcurrencySettings? concurrencySettings])
      : super(() => FailingWorker(entryPoint),
            concurrencySettings:
                concurrencySettings ?? ConcurrencySettings.fourIoThreads);

  @override
  Future noop() => execute((w) => w.noop());
}

class FailingWorker extends Worker implements FailingService {
  FailingWorker(dynamic entryPoint) : super(entryPoint);

  @override
  Future noop() => send(FailingService.noopCommand);
}
