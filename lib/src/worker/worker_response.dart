import 'dart:async';

import 'package:logger/logger.dart';
import 'package:meta/meta.dart';

import '../_impl/xplat/_helpers.dart';
import '../cast_helpers.dart';
import '../channel.dart';
import '../exceptions/squadron_error.dart';
import '../exceptions/squadron_exception.dart';
import 'worker_message.dart';

/// [WorkerResponse]s are used to communicate from [Worker]s to clients and
/// carry a single piece of data. [Future]-based services simply return a
/// single [WorkerResponse] with the result. [Stream]ing services will return
/// one [WorkerResponse]s for each stream item and mmust send a
/// [WorkerResponse.closeStream] message to indicate completion.
/// [WorkerResponse]s can also send error messages and log events.
extension type WorkerResponse._(List data) implements WorkerMessage {
  /// [WorkerResponse] with a valid [result]. If [result] is an [Iterable] but
  /// not a [List], it will be converted to a [List] by [wrapInPlace].
  static WorkerResponse ready([bool status = true]) => WorkerResponse._([
        microsecTimeStamp(), // 0 - travel time
        status, // 1 - ready
        null, // 2 - error
        null, // 3 - end of stream
        null, // 4 - log message
      ]);

  /// [WorkerResponse] with a valid [result]. If [result] is an [Iterable] but
  /// not a [List], it will be converted to a [List] by [wrapInPlace].
  static WorkerResponse withResult(dynamic result) => WorkerResponse._([
        microsecTimeStamp(), // 0 - travel time
        result, // 1 - result
        null, // 2 - error
        null, // 3 - end of stream
        null, // 4 - log message
      ]);

  /// [WorkerResponse] with an error message and an optional (string) [StackTrace].
  static WorkerResponse withError(SquadronException exception,
          [StackTrace? stackTrace]) =>
      WorkerResponse._([
        microsecTimeStamp(), // 0 - travel time
        null, // 1 - result
        exception, // 2 - error
        null, // 3 - end of stream
        null, // 4 - log message
      ]);

  /// [WorkerResponse] with log event information.
  static WorkerResponse log(LogEvent message) => WorkerResponse._([
        microsecTimeStamp(), // 0 - travel time
        null, // 1 - result
        null, // 2 - error
        null, // 3 - end of stream
        message.serialize(), // 4 - log message
      ]);

  /// Special [WorkerResponse] message to indicate the end of a stream.
  static WorkerResponse closeStream() => WorkerResponse._([
        microsecTimeStamp(), // 0 - travel time
        null, // 1 - result
        null, // 2 - error
        true, // 3 - end of stream
        null, // 4 - log message
      ]);

  /// Flag indicating the end of the [Stream]ing operation.
  bool get endOfStream => data[_$endOfStream];

  /// The [WorkerResponse] exception, if any.
  SquadronException? get error => data[_$error];

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
  bool unwrapInPlace(Channel channel) {
    unwrapTravelTime();
    final log = LogEventSerialization.deserialize(data[_$log]);
    if (log != null) {
      channel.logger?.log(log.level, log.message,
          time: log.time, error: log.error, stackTrace: log.stackTrace);
      return false;
    } else {
      data[_$error] = channel.exceptionManager.deserialize(data[_$error]);
      data[_$endOfStream] ??= false;
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

  static WorkerResponse from(List data) {
    if (data.length != 5) {
      throw SquadronErrorExt.create('Invalid worker response');
    }
    return WorkerResponse._(data);
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
