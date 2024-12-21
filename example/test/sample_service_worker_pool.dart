import 'dart:async';

import 'package:squadron/squadron.dart';

import 'identity_service.dart';
import 'sample_service.dart';

base class SampleWorkerPool extends WorkerPool<SampleWorker>
    implements SampleService {
  SampleWorkerPool(
      EntryPoint entryPoint,
      LocalWorker<IdentityService> identityServer,
      PlatformThreadHook? threadHook,
      ConcurrencySettings concurrencySettings)
      : super(
            (ExceptionManager exceptionManager) => SampleWorker(
                  entryPoint,
                  args: [identityServer.channel?.share().serialize()],
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

  @override
  Future<String> whoAreYouTalkingTo() => execute((w) => w.whoAreYouTalkingTo());
}

base class SampleWorker extends Worker implements SampleService {
  SampleWorker(super.entryPoint,
      {super.args, super.threadHook, super.exceptionManager});

  @override
  Future io({required int milliseconds}) =>
      send(SampleService.ioCommand, args: [milliseconds]);

  @override
  Future cpu({required int milliseconds}) =>
      send(SampleService.cpuCommand, args: [milliseconds]);

  @override
  Future<String> whoAreYouTalkingTo() =>
      send(SampleService.whoAreYouTalkingToCommand).then((x) => x as String);
}
