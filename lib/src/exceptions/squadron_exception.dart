import 'dart:async';
import 'dart:convert';

import 'package:cancelation_token/cancelation_token.dart';

import '../squadron.dart';
import '_well_known_exceptions.dart';
import 'worker_exception.dart';

/// Base abstract class for exceptions in Squadron.
abstract class SquadronException implements Exception {
  /// This method returns [error] if it is a [SquadronException] (enriching it with [workerId] and [command] if it
  /// is a [WorkerException]). Otherwise, it returns a new [WorkerException] wrapping [error] and [stackTrace].
  static SquadronException from(Object error,
      [StackTrace? stackTrace, String? workerId, int? command]) {
    if (error is WorkerException) {
      return error
        ..withCommand(command)
        ..withWorkerId(workerId);
    } else if (error is SquadronException) {
      return error;
    } else if (error is CanceledException) {
      return error.toSquadronException();
    } else if (error is TimeoutException) {
      return error.toSquadronException();
    } else {
      return WorkerException(
        error.toString(),
        stackTrace: stackTrace,
        workerId: workerId,
        command: command,
      );
    }
  }

  static SquadronException? fromString(String message) {
    try {
      final data = jsonDecode(message);
      if (data is List) {
        Squadron.debug('SquadronException.fromString is really used!');
        return Squadron.exceptionManager?.deserialize(data);
      }
    } catch (ex) {
      // not a String representing a SquadronException
    }
    return null;
  }

  String get message;

  @override
  String toString() => jsonEncode(serialize());

  /// The exception's [StackTrace].
  StackTrace? get stackTrace;

  /// Serializes the exception, i.e. returns a list of items that can cross thread boundaries.
  List serialize();

  /// Deserializes a [stackTrace] if any. Returns null if no [StackTrace] is provided.
  static StackTrace? loadStackTrace(String? stackTrace) =>
      (stackTrace == null) ? null : StackTrace.fromString(stackTrace);
}
