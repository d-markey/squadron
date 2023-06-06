import 'dart:async';

import 'package:meta/meta.dart';

import 'squadron.dart';
import 'worker.dart';
import 'squadron_exception.dart';
import 'worker_message.dart';

/// Make [WorkerResponse] a [WorkerMessage] to minimize serialization overhead.
typedef WorkerResponse = WorkerMessage;

/// Class used to communicate from a [Worker] to clients.
/// [WorkerResponse]s are used to provide individual results to the client. [Future]-based services simply return a
/// single [WorkerResponse] with the result. [Stream]ing services will return one [WorkerResponse]s for each stream
/// item and mmust send a [WorkerResponseImpl.closeStream] message to indicate completion. [WorkerResponse]s can also
/// send error messages.

/// Extension methods operating on a `List` as a [WorkerResponse]. [WorkerResponse] is used to provide individual
/// results to the client. [Future]-based services simply return a single [WorkerResponse] with the result. [Stream]
/// services return one [WorkerResponse] for each stream item and mmust send a [WorkerResponseImpl.closeStream]
/// message to indicate completion. A [WorkerResponse] can also be used to send error messages.
extension WorkerResponseImpl on WorkerResponse {
  static const _$result = 1;
  static const _$error = 2;
  static const _$endOfStream = 3;
  static const _$log = 4;

  /// [WorkerResponse] with a valid [result]. If [result] is an `Iterable` but not a `List`, it will be converted
  /// to a `List` by calling `toList()`.
  static WorkerResponse withResult(dynamic result) => [
        null, // 0 - travel time
        result, // 1 - result
        null, // 2 - error
        null, // 3 - end of stream
        null, // 4 - log message
      ];

  /// [WorkerResponse] with an error message and an optional (string) [StackTrace].
  static WorkerResponse withError(Object exception, [StackTrace? stackTrace]) =>
      [
        null, // 0 - travel time
        null, // 1 - result
        SquadronException.from(exception, stackTrace), // 2 - error
        null, // 3 - end of stream
        null, // 4 - log message
      ];

  /// [WorkerResponse] with an error message and an optional (string) [StackTrace].
  static WorkerResponse log(String message) => [
        null, // 0 - travel time
        null, // 1 - result
        null, // 2 - error
        null, // 3 - end of stream
        message, // 4 - log message
      ];

  /// Special [WorkerResponse] message to indicate the end of a stream.
  static WorkerResponse closeStream() => [
        null, // 0 - travel time
        null, // 1 - result
        null, // 2 - error
        true, // 3 - end of stream
        null, // 4 - log message
      ];

  /// Flag indicating the end of the [Stream]ing operation.
  bool get endOfStream => this[_$endOfStream];

  /// The [WorkerResponse] exception, if any.
  SquadronException? get error => this[_$error];

  /// Retrieves the result associated to this [WorkerResponse]. If the [WorkerResponse] contains an error,
  /// an the [error] exception is thrown.
  dynamic get result {
    final err = error;
    if (err != null) {
      throw err;
    } else {
      return this[_$result];
    }
  }
}

@internal
extension WorkerResponseExt on WorkerResponse {
  static const _$result = WorkerResponseImpl._$result;
  static const _$error = WorkerResponseImpl._$error;
  static const _$endOfStream = WorkerResponseImpl._$endOfStream;
  static const _$log = WorkerResponseImpl._$log;

  /// In-place deserialization of a [WorkerResponse] sent by the worker. Returns `false` if
  /// the message requires no further processing (currently used for log messages only).
  bool unwrapResponse() {
    final log = this[_$log];
    if (log != null) {
      getSquadronLogger()?.log(log);
      return false;
    } else {
      this[_$error] = SquadronException.deserialize(this[_$error]);
      this[_$endOfStream] ??= false;
      setTravelTime();
    }
    return true;
  }

  /// In-place serialization of a [WorkerResponse].
  void wrapResponse() {
    final res = this[_$result];
    if (res is! List && res is Iterable) {
      this[_$result] = res.toList();
    }
    this[_$error] = (this[_$error] as SquadronException?)?.serialize();
    initTravelTime();
  }
}
