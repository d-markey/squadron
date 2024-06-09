import 'dart:async';

import 'package:logger/logger.dart';
import 'package:meta/meta.dart';

import '../../squadron.dart';
import '../_impl/xplat/_helpers.dart';
import 'worker_message.dart';

/// [WorkerResponse]s are used to communicate from [Worker]s to clients and
/// carry a single piece of data. [Future]-based services simply return a
/// single [WorkerResponse] with the result. [Stream]ing services will return
/// one [WorkerResponse]s for each stream item and mmust send a
/// [WorkerResponse.closeStream] message to indicate completion.
/// [WorkerResponse]s can also send error messages and log events.
extension type WorkerResponse(List data) implements WorkerMessage {
  /// [WorkerResponse] with a valid [result]. If [result] is an [Iterable] but
  /// not a [List], it will be converted to a [List] by [wrapInPlace].
  static WorkerResponse withResult(dynamic result) => WorkerResponse([
        microsecTimeStamp(), // 0 - travel time
        result, // 1 - result
        null, // 2 - error
        null, // 3 - end of stream
        null, // 4 - log message
      ]);

  /// [WorkerResponse] with an error message and an optional (string) [StackTrace].
  static WorkerResponse withError(SquadronException exception,
          [StackTrace? stackTrace]) =>
      WorkerResponse([
        microsecTimeStamp(), // 0 - travel time
        null, // 1 - result
        exception, // 2 - error
        null, // 3 - end of stream
        null, // 4 - log message
      ]);

  /// [WorkerResponse] with log event information.
  static WorkerResponse log(LogEvent message) => WorkerResponse([
        microsecTimeStamp(), // 0 - travel time
        null, // 1 - result
        null, // 2 - error
        null, // 3 - end of stream
        message.serialize(), // 4 - log message
      ]);

  /// Special [WorkerResponse] message to indicate the end of a stream.
  static WorkerResponse closeStream() => WorkerResponse([
        microsecTimeStamp(), // 0 - travel time
        null, // 1 - result
        null, // 2 - error
        true, // 3 - end of stream
        null, // 4 - log message
      ]);

  /// Flag indicating the end of the [Stream]ing operation.
  bool get endOfStream => data[_$endOfStream];

  /// The [WorkerResponse] exception, if any.
  dynamic get error => data[_$error];

  /// Retrieves the result associated to this [WorkerResponse]. If the
  /// [WorkerResponse] contains an error, an the [error] exception is thrown.
  dynamic get result {
    final err = error;
    if (err != null) {
      throw err;
    } else {
      return data[_$result];
    }
  }
}

// 0 is reserved for travel time
const _$result = 1;
const _$error = 2;
const _$endOfStream = 3;
const _$log = 4;

@internal
extension WorkerResponseExt on WorkerResponse {
  /// In-place deserialization of a [WorkerResponse] sent by the worker.
  /// Returns `false` if the message requires no further processing (currently
  /// used for log messages only).
  bool unwrapInPlace(ExceptionManager exceptionManager, Logger? logger) {
    final log = LogEventSerialization.deserialize(data[_$log]);
    if (log != null) {
      logger?.log(log.level, log.message,
          time: log.time, error: log.error, stackTrace: log.stackTrace);
      return false;
    } else {
      data[_$error] = exceptionManager.deserialize(data[_$error]);
      data[_$endOfStream] ??= false;
      unwrapTravelTime();
      return true;
    }
  }

  /// In-place serialization of a [WorkerResponse].
  List wrapInPlace() {
    final result = data[_$result];
    if (result is Iterable && result is! List) {
      data[_$result] = result.toList();
    }
    data[_$error] = (data[_$error] as SquadronException?)?.serialize();
    return data;
  }
}

extension LogEventSerialization on LogEvent {
  List serialize() => [
        level.value,
        _stringify(message),
        microsecTimeStamp(time),
        error?.toString(),
        stackTrace?.toString(),
      ];

  static LogEvent? deserialize(List? props) => (props == null)
      ? null
      : LogEvent(
          _getLevel(Cast.toNullableInt(props[0])),
          props[1],
          time: fromMicrosecTimeStamp(Cast.toNullableInt(props[2])),
          error: props[3],
          stackTrace: SquadronException.loadStackTrace(props[4]),
        );

  static Level _getLevel(int? value) {
    if (value == null) return Level.debug;
    return Level.values.where((l) => l.value == value).first;
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
