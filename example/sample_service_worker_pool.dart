import 'dart:async';

import 'package:squadron/squadron.dart';

import 'identity_service.dart';
import 'sample_service.dart';

class SampleWorkerPool extends WorkerPool<SampleWorker>
    implements SampleService {
  SampleWorkerPool(
      EntryPoint entryPoint,
      LocalWorker<IdentityService> identityServer,
      PlatformThreadHook? threadHook,
      ConcurrencySettings concurrencySettings)
      : super(
            () => SampleWorker(entryPoint,
                args: [identityServer.channel?.share().serialize()],
                threadHook: threadHook),
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

class SampleWorker extends Worker<SampleService> implements SampleService {
  SampleWorker(super.entryPoint, {super.args, super.threadHook});

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
