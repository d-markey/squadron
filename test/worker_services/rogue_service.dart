import 'dart:async';

import 'package:squadron/squadron_service.dart';

class RogueService implements WorkerService {
  FutureOr throwWorkerException() =>
      throw WorkerException('intended worker exception');

  FutureOr throwException() => throw Exception('intended exception');

  static const workerException = 1;
  static const exception = 2;

  @override
  late final Map<int, CommandHandler> operations = {
    RogueService.workerException: (r) => throwWorkerException(),
    RogueService.exception: (r) => throwException(),
  };
}
