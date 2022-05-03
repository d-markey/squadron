import 'dart:async';

import 'package:squadron/squadron.dart';

import 'identity_service.dart';
import 'sample_service.dart';

class SampleWorkerPool extends WorkerPool<SampleWorker>
    implements SampleService {
  SampleWorkerPool(
      dynamic entryPoint,
      LocalWorker<IdentityService> identityServer,
      ConcurrencySettings concurrencySettings)
      : super(
            () => SampleWorker(entryPoint,
                args: [identityServer.channel?.share().serialize()]),
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
  SampleWorker(dynamic entryPoint, {List args = const []})
      : super(entryPoint, args: args);

  @override
  Future io({required int milliseconds}) =>
      send(SampleService.ioCommand, [milliseconds]);

  @override
  Future cpu({required int milliseconds}) =>
      send(SampleService.cpuCommand, [milliseconds]);

  @override
  Future<String> whoAreYouTalkingTo() =>
      send(SampleService.whoAreYouTalkingToCommand, []);
}
