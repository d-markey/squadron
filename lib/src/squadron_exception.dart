import 'dart:async';
import 'dart:convert';

import 'squadron_error.dart';
import 'worker_exception.dart';

typedef WorkerExceptionDeserializer = WorkerException? Function(List data);

/// Base abstract class for exceptions in Squadron.
abstract class SquadronException implements Exception {
  /// This factory returns [error] if it is a [SquadronException] (enriching it with [workerId] and [command] if it
  /// is a [WorkerException]). Otherwise, it returns a new [WorkerException] wrapping [error] and [stackTrace].
  factory SquadronException.from(
      {required Object error,
      StackTrace? stackTrace,
      String? workerId,
      int? command}) {
    if (error is SquadronError) {
      return error;
    } else if (error is WorkerException) {
      return error
          .withCommand(command)
          .withWorkerId(workerId)
          .withCommand(command);
    } else if (error is TimeoutException) {
      return TaskTimeoutException(
          message: error.message ?? 'Task timeout',
          duration: error.duration,
          workerId: workerId,
          command: command);
    } else {
      return WorkerException(error.toString(),
          stackTrace: stackTrace, workerId: workerId, command: command);
    }
  }

  static SquadronException? fromString(String message) {
    try {
      final data = jsonDecode(message);
      if (data is List) {
        return deserialize(data);
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

  static final _customDeserializers = <WorkerExceptionDeserializer>[];

  /// Registers the deserializer for a custom [WorkerException].
  static void registerExceptionDeserializer(
      WorkerExceptionDeserializer deserializer) {
    _customDeserializers.add(deserializer);
  }

  /// Deserializes a [stackTrace] if any. Ruturns null if no [StackTrace] is provided.
  static StackTrace? loadStackTrace(String? stackTrace) =>
      (stackTrace == null) ? null : StackTrace.fromString(stackTrace);

  /// Deserializes a [List] that was produced by [serialize].
  static SquadronException? deserialize(List? data) {
    if (data == null) {
      return null;
    }
    SquadronException? error;
    try {
      error = SquadronError.deserialize(data) ??
          WorkerException.deserialize(data) ??
          CancelledException.deserialize(data) ??
          TaskTimeoutException.deserialize(data);
      if (error == null) {
        for (var i = 0; i < _customDeserializers.length; i++) {
          final deserializer = _customDeserializers[i];
          error = deserializer(data);
          if (error != null) {
            break;
          }
        }
      }
      error ??= newSquadronError(
          'failed to deserialize exception information: $data');
    } catch (ex) {
      error =
          newSquadronError('failed to deserialize exception information: $ex');
    }
    return error;
  }
}
