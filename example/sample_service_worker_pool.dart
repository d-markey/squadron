import 'dart:async';

import 'package:squadron/squadron.dart';

import 'identity_service.dart';
import 'sample_service.dart';

class SampleWorkerPool extends WorkerPool<SampleWorker>
    implements SampleService {
  SampleWorkerPool(
      EntryPoint entryPoint,
      LocalWorker<IdentityService> identityServer,
      PlatformWorkerHook? platformWorkerHook,
      ConcurrencySettings concurrencySettings)
      : super(
            () => SampleWorker(entryPoint,
                args: [identityServer.channel?.share().serialize()],
                platformWorkerHook: platformWorkerHook),
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

class SampleWorker extends Worker implements SampleService {
  SampleWorker(EntryPoint entryPoint,
      {List args = const [], PlatformWorkerHook? platformWorkerHook})
      : super(entryPoint, args: args, platformWorkerHook: platformWorkerHook);

  @override
  Future io({required int milliseconds}) =>
      send(SampleService.ioCommand, args: [milliseconds]);

  @override
  Future cpu({required int milliseconds}) =>
      send(SampleService.cpuCommand, args: [milliseconds]);

  @override
  Future<String> whoAreYouTalkingTo() =>
      send(SampleService.whoAreYouTalkingToCommand);
}
