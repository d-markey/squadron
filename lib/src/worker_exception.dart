import 'dart:async';

import 'package:meta/meta.dart';

import 'squadron_exception.dart';

/// Exception to keep track of errors encountered in a worker.
class WorkerException extends SquadronException {
  /// Creates a new [WorkerException] to capture error context.
  WorkerException(this.message,
      {StackTrace? stackTrace, String? workerId, int? command})
      : _stackTrace = stackTrace,
        _workerId = workerId,
        _command = command {
    if (_stackTrace == null) {
      try {
        _stackTrace = StackTrace.current;
      } catch (_) {
        // ignore...
      }
    }
  }

  static const _$type = 0;
  static const _$message = 1;
  static const _$stackTrace = 2;
  static const _$workerId = 3;
  static const _$command = 4;

  static const _$typeMarker = '\$W';

  @override
  List serialize() => List.unmodifiable([
        _$typeMarker,
        message,
        _stackTrace?.toString(),
        _workerId,
        _command,
      ]);

  static WorkerException? deserialize(List data) =>
      (data[_$type] == _$typeMarker)
          ? WorkerException(data[_$message],
              stackTrace: SquadronException.loadStackTrace(data[_$stackTrace]),
              workerId: data[_$workerId],
              command: data[_$command])
          : null;

  /// Message.
  @override
  final String message;

  /// Stack trace associated to the original exception.
  @override
  StackTrace? get stackTrace => _stackTrace;
  StackTrace? _stackTrace;

  /// Worker ID.
  String? get workerId => _workerId;
  String? _workerId;

  /// Command.
  int? get command => _command;
  int? _command;
}

/// Exception to keep track of task cancellation.
class CancelledException extends WorkerException {
  CancelledException(
      {String? message, StackTrace? stackTrace, String? workerId, int? command})
      : super(message ?? 'The task has been cancelled',
            stackTrace: stackTrace, workerId: workerId, command: command);

  static const _$type = 0;
  static const _$message = 1;
  static const _$stackTrace = 2;
  static const _$workerId = 3;
  static const _$command = 4;

  static const _$typeMarker = '\$C';

  @override
  List serialize() => List.unmodifiable([
        _$typeMarker,
        message,
        _stackTrace?.toString(),
        _workerId,
        _command,
      ]);

  static CancelledException? deserialize(List data) =>
      (data[_$type] == _$typeMarker)
          ? CancelledException(
              message: data[_$message],
              stackTrace: SquadronException.loadStackTrace(data[_$stackTrace]),
              workerId: data[_$workerId],
              command: data[_$command])
          : null;
}

/// Exception to keep track of task timeouts.
class TaskTimeoutException extends CancelledException
    implements TimeoutException {
  /// Creates a new [TaskTimeoutException].
  TaskTimeoutException(
      {String? message,
      StackTrace? stackTrace,
      String? workerId,
      int? command,
      this.duration})
      : super(
            message: message ?? 'The task timed out',
            stackTrace: stackTrace,
            workerId: workerId,
            command: command);

  static const _$type = 0;
  static const _$message = 1;
  static const _$stackTrace = 2;
  static const _$workerId = 3;
  static const _$command = 4;
  static const _$duration = 5;

  static const _$typeMarker = '\$T';

  @override
  List serialize() => List.unmodifiable([
        _$typeMarker,
        message,
        _stackTrace?.toString(),
        _workerId,
        _command,
        duration?.inMicroseconds
      ]);

  @override
  final Duration? duration;

  static TaskTimeoutException? deserialize(List data) =>
      (data[_$type] == _$typeMarker)
          ? TaskTimeoutException(
              message: data[_$message],
              stackTrace: SquadronException.loadStackTrace(data[_$stackTrace]),
              workerId: data[_$workerId],
              command: data[_$command],
              duration: (data[_$duration] == null)
                  ? null
                  : Duration(microseconds: data[_$duration]))
          : null;
}

@internal
extension WorkerExceptionExt on WorkerException {
  WorkerException withWorkerId(String? workerId) {
    _workerId ??= workerId;
    return this;
  }

  WorkerException withCommand(int? command) {
    _command ??= command;
    return this;
  }

  WorkerException withStackTrace(StackTrace? stackTrace) {
    _stackTrace ??= stackTrace;
    return this;
  }
}
