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

/// Exception to keep track of task cancellations.
class CancelledException extends WorkerException {
  /// Creates a new [CancelledException].
  CancelledException({String? message, String? stackTrace, String? workerId})
      : super(message ?? 'The task has been cancelled',
            stackTrace: stackTrace, workerId: workerId);
}
