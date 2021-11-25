import 'dart:async';

/// Exception to keep track of errors encountered in a worker.
class WorkerException implements Exception {
  /// Creates a new [WorkerException] to capture error context.
  WorkerException(this.message, {String? stackTrace, this.workerId})
      : stackTrace = stackTrace ?? StackTrace.current.toString();

  WorkerException withWorkerId(String workerId) =>
      WorkerException(message, stackTrace: stackTrace, workerId: workerId);

  /// Message (or string representation of the exception).
  final String message;

  /// String representation of the stack trace associated to the original exception.
  final String? stackTrace;

  /// Worker ID.
  final String? workerId;

  @override
  String toString() => 'WorkerException: $message\n$stackTrace';
}

/// Exception to keep track of task cancellations.
class CancelledException extends WorkerException {
  /// Creates a new [CancelledException].
  CancelledException(String? message,
      {String? stackTrace, String? workerId})
      : super(message ?? 'The task has been cancelled',
            stackTrace: stackTrace, workerId: workerId);

  @override
  CancelledException withWorkerId(String workerId) =>
      CancelledException(message,
          stackTrace: stackTrace, workerId: workerId);
}

/// Exception to keep track of task timeouts.
class TaskTimeoutException extends WorkerException implements TimeoutException {
  /// Creates a new [TaskTimeoutException].
  TaskTimeoutException(String? message,
      {String? stackTrace, String? workerId, this.duration})
      : super(message ?? 'The task timed out',
            stackTrace: stackTrace, workerId: workerId);

  @override
  TaskTimeoutException withWorkerId(String workerId) =>
      TaskTimeoutException(message,
          stackTrace: stackTrace, workerId: workerId, duration: duration);

  @override
  final Duration? duration;
}
