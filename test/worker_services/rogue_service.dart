import 'dart:async';

import 'package:squadron/squadron.dart';

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

class RogueService {
  FutureOr throwWorkerException() =>
      throw WorkerException('intended worker exception');

  FutureOr throwException() => throw Exception('intended exception');

  static const workerException = 1;
  static const exception = 2;

  Map<int, CommandHandler> get operations => {
        RogueService.workerException: (r) => throwWorkerException(),
        RogueService.exception: (r) => throwException(),
      };
}
