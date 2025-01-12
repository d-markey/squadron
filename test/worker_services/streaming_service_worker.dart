import 'dart:async';

import 'package:squadron/squadron.dart';

import '../src/test_context.dart';
import 'squadron_version.dart';
import 'streaming_service.dart';

class StreamingServiceWorkerPool extends WorkerPool<StreamingServiceWorker>
    with PoolVersion<StreamingServiceWorker>
    implements StreamingService {
  StreamingServiceWorkerPool(
      TestContext context, ConcurrencySettings? concurrencySettings,
      [ExceptionManager? exceptionManager])
      : super(
          (ExceptionManager exceptionManager) => StreamingServiceWorker(context,
              exceptionManager: exceptionManager),
          concurrencySettings:
              concurrencySettings ?? ConcurrencySettings.fourIoThreads,
          exceptionManager: exceptionManager,
        );

  @override
  Future<int> getMonitored() => execute((w) => w.getMonitored());

  @override
  Stream<int> monitoredStream() => stream((w) => w.monitoredStream());
}

class StreamingServiceWorker extends Worker
    with WorkerVersion
    implements StreamingService {
  StreamingServiceWorker(TestContext context,
      {PlatformThreadHook? hook, ExceptionManager? exceptionManager})
      : super(
          context.entryPoints.streaming!,
          threadHook: hook,
          exceptionManager: exceptionManager,
        );

  @override
  Future<int> getMonitored() =>
      send(StreamingService.$getMonitored).then(_toInt);

  @override
  Stream<int> monitoredStream() =>
      stream(StreamingService.$monitoredStream).map(_toInt);

  Cast<int> get _toInt => Squadron.converter.value<int>();
}
