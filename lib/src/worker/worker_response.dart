import 'dart:async';

import 'package:logger/logger.dart';
import 'package:meta/meta.dart';

import '../_impl/xplat/_helpers.dart';
import '../exceptions/exception_manager.dart';
import '../exceptions/squadron_exception.dart';
import 'worker_message.dart';

/// Make [WorkerResponse] a [WorkerMessage] to minimize serialization overhead.
typedef WorkerResponse = WorkerMessage;

/// Class used to communicate from a [Worker] to clients.
/// [WorkerResponse]s are used to provide individual results to the client.
/// [Future]-based services simply return a single [WorkerResponse] with the
/// result. [Stream]ing services will return one [WorkerResponse]s for each
/// stream item and mmust send a [WorkerResponseImpl.closeStream] message to
/// indicate completion. [WorkerResponse]s can also send error messages.

/// Extension methods operating on a `List` as a [WorkerResponse].
/// [WorkerResponse] is used to provide individual results to the client.
/// [Future]-based services simply return a single [WorkerResponse] with the
/// result. [Stream] services return one [WorkerResponse] for each stream item
/// and mmust send a [WorkerResponseImpl.closeStream] message to indicate
/// completion. A [WorkerResponse] can also be used to send error messages.
extension WorkerResponseImpl on WorkerResponse {
  // 0 is reserved for travel time
  static const _$result = 1;
  static const _$error = 2;
  static const _$endOfStream = 3;
  static const _$log = 4;

  /// [WorkerResponse] with a valid [result]. If [result] is an [Iterable] but
  /// not a [List], it will be converted to a [List] by calling [List.toList].
  static WorkerResponse withResult(dynamic result) => [
        microsecTimeStamp(), // 0 - travel time
        result, // 1 - result
        null, // 2 - error
        null, // 3 - end of stream
        null, // 4 - log message
      ];

  /// [WorkerResponse] with an error message and an optional (string) [StackTrace].
  static WorkerResponse withError(SquadronException exception,
          [StackTrace? stackTrace]) =>
      [
        microsecTimeStamp(), // 0 - travel time
        null, // 1 - result
        exception, // 2 - error
        null, // 3 - end of stream
        null, // 4 - log message
      ];

  /// [WorkerResponse] with log event information.
  static WorkerResponse log(LogEvent message) => [
        microsecTimeStamp(), // 0 - travel time
        null, // 1 - result
        null, // 2 - error
        null, // 3 - end of stream
        message.serialize(), // 4 - log message
      ];

  /// Special [WorkerResponse] message to indicate the end of a stream.
  static WorkerResponse closeStream() => [
        microsecTimeStamp(), // 0 - travel time
        null, // 1 - result
        null, // 2 - error
        true, // 3 - end of stream
        null, // 4 - log message
      ];

  /// Flag indicating the end of the [Stream]ing operation.
  bool get endOfStream => this[_$endOfStream];

  /// The [WorkerResponse] exception, if any.
  dynamic get error => this[_$error];

  /// Retrieves the result associated to this [WorkerResponse]. If the
  /// [WorkerResponse] contains an error, an the [error] exception is thrown.
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
  // 0 is reserved for travel time
  static const _$result = WorkerResponseImpl._$result;
  static const _$error = WorkerResponseImpl._$error;
  static const _$endOfStream = WorkerResponseImpl._$endOfStream;
  static const _$log = WorkerResponseImpl._$log;

  /// In-place deserialization of a [WorkerResponse] sent by the worker.
  /// Returns `false` if the message requires no further processing (currently
  /// used for log messages only).
  bool unwrapResponseInPlace(
      ExceptionManager exceptionManager, Logger? logger) {
    final log = LogEventSerialization.deserialize(this[_$log]);
    if (log != null) {
      logger?.log(log.level, log.message,
          time: log.time, error: log.error, stackTrace: log.stackTrace);
      return false;
    } else {
      this[_$error] = exceptionManager.deserialize(this[_$error]);
      this[_$endOfStream] ??= false;
      unwrapTravelTime();
    }
    return true;
  }

  /// In-place serialization of a [WorkerResponse].
  void wrapResponseInPlace() {
    final result = this[_$result];
    if (result is! List && result is Iterable) {
      this[_$result] = result.toList();
    }
    this[_$error] = (this[_$error] as SquadronException?)?.serialize();
  }
}

extension LogEventSerialization on LogEvent {
  List serialize() => [
        level.value,
        _stringify(message)?.toString(),
        microsecTimeStamp(time),
        error?.toString(),
        stackTrace?.toString(),
      ];

  static LogEvent? deserialize(List? props) => (props == null)
      ? null
      : LogEvent(
          _getLevel(props[0]),
          props[1],
          time: fromMicrosecTimeStamp(props[2]),
          error: props[3],
          stackTrace: SquadronException.loadStackTrace(props[4]),
        );

  static Level _getLevel(int? value) {
    if (value == null) return Level.debug;
    return Level.values.where((_) => _.value == value).first;
  }

  static String? _stringify(dynamic message) {
    if (message is Function) {
      try {
        return _stringify(message());
      } catch (ex) {
        return 'Deferred message failed with error: $ex';
      }
    } else {
      return message.toString();
    }
  }
}
