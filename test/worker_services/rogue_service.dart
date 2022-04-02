import 'dart:async';

import 'package:squadron/squadron_service.dart';

import '../classes/custom_exception.dart';
import '../classes/untransferable.dart';

class RogueService implements WorkerService {
  FutureOr throwWorkerException() =>
      throw WorkerException('intentional worker exception');

  FutureOr throwException() => throw Exception('intentional exception');

  FutureOr throwCustomException() =>
      throw CustomException('intentional CUSTOM exception');

  FutureOr<dynamic> forward(dynamic data) => data;

  FutureOr missingOperation() {}

  FutureOr<dynamic> invalidResponse() => getUntransferable();

  FutureOr<bool> ping() => true;

  static const workerExceptionCommand = 1;
  static const exceptionCommand = 2;
  static const customExceptionCommand = 3;
  static const forwardCommand = 4;
  static const missingCommand = 5;
  static const invalidResponseCommand = 6;
  static const pingCommand = 7;

  @override
  late final Map<int, CommandHandler> operations = {
    workerExceptionCommand: (r) => throwWorkerException(),
    exceptionCommand: (r) => throwException(),
    customExceptionCommand: (r) => throwCustomException(),
    forwardCommand: (r) => forward(r.args[0]),
    // missingCommand intentionaly missing
    invalidResponseCommand: (r) => invalidResponse(),
    pingCommand: (r) => ping(),
  };
}
