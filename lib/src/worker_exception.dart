import 'dart:async';

/// Exception to keep track of errors encountered in a worker.
class WorkerException implements Exception {
  /// Creates a new [WorkerException] to capture error context.
  WorkerException(this.message,
      {String? stackTrace, this.workerId, this.command})
      : stackTrace = stackTrace ?? StackTrace.current.toString();

  /// Message (or string representation of the exception).
  final String message;

  /// String representation of the stack trace associated to the original exception.
  final String? stackTrace;

  /// Worker ID.
  final String? workerId;

  /// Command.
  final int? command;

  @override
  String toString() {
    final info = <String>[];
    if (workerId != null) info.add('workerId=$workerId');
    if (command != null) info.add('command=$command');
    if (info.isEmpty) {
      return 'WorkerException: $message\n$stackTrace';
    } else {
      return 'WorkerException (${info.join(', ')}): $message\n$stackTrace';
    }
  }
}

/// Exception to keep track of task cancellation.
class CancelledException extends WorkerException {
  CancelledException(
      {String? message, String? stackTrace, String? workerId, int? command})
      : super(message ?? 'The task has been cancelled',
            stackTrace: stackTrace, workerId: workerId, command: command);
}

/// Exception to keep track of task timeouts.
class TaskTimeoutException extends CancelledException
    implements TimeoutException {
  /// Creates a new [TaskTimeoutException].
  TaskTimeoutException(
      {String? message,
      String? stackTrace,
      String? workerId,
      int? command,
      this.duration})
      : super(
            message: message ?? 'The task timed out',
            stackTrace: stackTrace,
            workerId: workerId,
            command: command);

  @override
  final Duration? duration;
}

extension WorkerExceptionDetails on WorkerException {
  WorkerException withWorkerId(String? workerId) {
    final type = runtimeType;
    if (type == TaskTimeoutException) {
      return TaskTimeoutException(
          message: message,
          stackTrace: stackTrace,
          duration: (this as TaskTimeoutException).duration,
          workerId: workerId,
          command: command);
    } else if (type == CancelledException) {
      return CancelledException(
          message: message,
          stackTrace: stackTrace,
          workerId: workerId,
          command: command);
    } else {
      return WorkerException(message,
          stackTrace: stackTrace, workerId: workerId, command: command);
    }
  }

  WorkerException withCommand(int command) {
    final type = runtimeType;
    if (type == TaskTimeoutException) {
      return TaskTimeoutException(
          message: message,
          stackTrace: stackTrace,
          duration: (this as TaskTimeoutException).duration,
          workerId: workerId,
          command: command);
    } else if (type == CancelledException) {
      return CancelledException(
          message: message,
          stackTrace: stackTrace,
          workerId: workerId,
          command: command);
    } else {
      return WorkerException(message,
          stackTrace: stackTrace, workerId: workerId, command: command);
    }
  }
}
