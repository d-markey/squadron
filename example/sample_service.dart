import 'dart:async';

import 'package:logger/logger.dart';
import 'package:squadron/squadron.dart';

import 'identity_service.dart';

abstract class SampleService {
  Future io({required int milliseconds});
  FutureOr cpu({required int milliseconds});
  FutureOr<String> whoAreYouTalkingTo();

  // command IDs
  static const ioCommand = 1;
  static const cpuCommand = 2;
  static const whoAreYouTalkingToCommand = 3;
}

class SampleServiceImpl implements SampleService, WorkerService {
  SampleServiceImpl(this._identityClient);

  final IdentityClient _identityClient;
  final Logger _logger = Logger(level: Level.all);

  @override
  Future io({required int milliseconds}) =>
      Future.delayed(Duration(milliseconds: milliseconds));

  @override
  void cpu({required int milliseconds}) {
    final sw = Stopwatch()..start();
    while (sw.elapsedMilliseconds < milliseconds) {/* cpu */}
  }

  @override
  Future<String> whoAreYouTalkingTo() async {
    // this is where the local worker is called
    final localWorkerIdentity = await _identityClient.whoAreYou();
    _logger.i('talking to $localWorkerIdentity');
    return 'I am $threadId, and I am talking to $localWorkerIdentity.';
  }

  // command IDs --> command handlers
  @override
  late final Map<int, CommandHandler> operations = {
    SampleService.ioCommand: (WorkerRequest r) => io(milliseconds: r.args[0]),
    SampleService.cpuCommand: (WorkerRequest r) => cpu(milliseconds: r.args[0]),
    SampleService.whoAreYouTalkingToCommand: (WorkerRequest r) =>
        whoAreYouTalkingTo(),
  };
}
