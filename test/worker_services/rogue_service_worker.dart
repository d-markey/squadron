import 'dart:async';

import 'package:squadron/squadron.dart';

import 'rogue_service.dart';

class RogueWorker extends Worker implements RogueService {
  RogueWorker(dynamic entryPoint) : super(entryPoint);

  @override
  Future throwWorkerException() => send(RogueService.workerException);

  @override
  Future throwException() => send(RogueService.exception);
}
