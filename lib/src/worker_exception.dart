import 'dart:async';

/// Exception to keep track of errors encountered in a worker.
class WorkerException implements Exception {
  /// Creates a new [WorkerException] to capture error context.
  WorkerException(this.message, {String? stackTrace, this.workerId})
      : stackTrace = stackTrace ?? StackTrace.current.toString();

  /// Message (or string representation of the exception).
  final String message;

  /// String representation of the stack trace associated to the original exception.
  final String? stackTrace;

  /// Worker ID.
  final String? workerId;

  @override
  String toString() => 'WorkerException: $message\n$stackTrace';
}

/// Exception to keep track of task cancellation.
class CancelledException extends WorkerException {
  CancelledException({String? message, String? stackTrace, String? workerId})
      : super(message ?? 'The task has been cancelled',
            stackTrace: stackTrace, workerId: workerId);
}

/// Exception to keep track of task timeouts.
class TaskTimeoutException extends CancelledException
    implements TimeoutException {
  /// Creates a new [TaskTimeoutException].
  TaskTimeoutException(
      {String? message, String? stackTrace, String? workerId, this.duration})
      : super(
            message: message ?? 'The task timed out',
            stackTrace: stackTrace,
            workerId: workerId);

  @override
  final Duration? duration;
}

extension WorkerIdSetter on WorkerException {
  WorkerException withWorkerId(String? workerId) {
    final type = runtimeType;
    if (type == TaskTimeoutException) {
      return TaskTimeoutException(
          message: message,
          stackTrace: stackTrace,
          duration: (this as TaskTimeoutException).duration,
          workerId: workerId);
    } else if (type == CancelledException) {
      return CancelledException(
          message: message, stackTrace: stackTrace, workerId: workerId);
    } else {
      return CancelledException(
          message: message, stackTrace: stackTrace, workerId: workerId);
    }
  }
}
