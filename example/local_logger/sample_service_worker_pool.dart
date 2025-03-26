import 'dart:async';

import 'package:squadron/squadron.dart';

import 'logging_service.dart';
import 'sample_service.dart';

base class SampleWorkerPool extends WorkerPool<SampleWorker>
    implements SampleService {
  SampleWorkerPool(
      EntryPoint entryPoint,
      LocalWorker<LoggingService> loggingServer,
      PlatformThreadHook? threadHook,
      ConcurrencySettings concurrencySettings)
      : super(
            (ExceptionManager exceptionManager) => SampleWorker(
                  entryPoint,
                  loggingServer,
                  threadHook: threadHook,
                  exceptionManager: exceptionManager,
                ),
            concurrencySettings: concurrencySettings);

  @override
  Future io({required int milliseconds}) =>
      execute((w) => w.io(milliseconds: milliseconds));

  @override
  Future cpu({required int milliseconds}) =>
      execute((w) => w.cpu(milliseconds: milliseconds));
}

base class SampleWorker extends Worker implements SampleService {
  SampleWorker(super.entryPoint, LocalWorker<LoggingService> loggingServer,
      {super.threadHook, super.exceptionManager})
      : _channel = loggingServer.channel?.share();

  final Channel? _channel;

  @override
  List? getStartArgs() => [_channel?.serialize()];

  @override
  Future io({required int milliseconds}) =>
      send(SampleService.ioCommand, args: [milliseconds]);

  @override
  Future cpu({required int milliseconds}) =>
      send(SampleService.cpuCommand, args: [milliseconds]);

  @override
  void stop() {
    _channel?.close();
    super.stop();
  }
}
