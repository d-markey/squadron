class WorkerException implements Exception {
  WorkerException(this.message, { this.stackTrace, this.workerId });

  final String message;
  final String? stackTrace;
  final String? workerId;
}
