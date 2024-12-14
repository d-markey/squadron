import 'dart:async';
import 'dart:convert';

import 'package:cancelation_token/cancelation_token.dart';

import '_builtin_exceptions.dart';
import 'worker_exception.dart';

/// Base abstract class for exceptions in Squadron.
abstract class SquadronException implements Exception {
  SquadronException.init(this.message, [this._stackTrace]) {
    if (_stackTrace == null) {
      try {
        _stackTrace = StackTrace.current;
      } catch (_, st) {
        // failed, take the opportunity to get the stack trace from this exception!
        _stackTrace = st;
      }
    }
  }

  /// This method returns [error] if it is a [SquadronException] (enriching it
  /// with [command] if it is a [WorkerException]). Otherwise, it returns a new
  /// [WorkerException] wrapping [error] and [stackTrace].
  static SquadronException from(Object error,
      [StackTrace? stackTrace, int? command]) {
    if (error is WorkerException) {
      if (command != null) error.setCommand(command);
      return error;
    } else if (error is SquadronException) {
      return error;
    } else if (error is CanceledException) {
      return error.toSquadronException();
    } else if (error is TimeoutException) {
      return error.toSquadronException();
    } else {
      return WorkerException(error.toString(), stackTrace, command);
    }
  }

  final String message;

  /// The exception's [StackTrace].
  StackTrace? get stackTrace => _stackTrace;
  StackTrace? _stackTrace;

  @override
  String toString() => jsonEncode(serialize());

  /// Serializes the exception, i.e. returns a list of items that can cross thread boundaries.
  List serialize();

  /// Deserializes a [stackTrace] if any. Returns null if no [StackTrace] is provided.
  static StackTrace? loadStackTrace(String? stackTrace) =>
      (stackTrace == null) ? null : StackTrace.fromString(stackTrace);
}
