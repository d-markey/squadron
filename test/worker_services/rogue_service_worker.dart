import 'dart:async';

import 'package:squadron/squadron.dart';

import 'rogue_service.dart';

class RogueWorker extends Worker implements RogueService {
  RogueWorker(dynamic entryPoint, {String? id, List args = const []})
      : super(entryPoint, id: id, args: args);

  @override
  Future throwWorkerException() => send(RogueService.workerException);

  @override
  Future throwException() => send(RogueService.exception);

  @override
  final Map<int, CommandHandler> operations = const {};
}
