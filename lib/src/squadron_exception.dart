/// Exception to keep track of errors encountered in a worker.
class SquadronException implements Exception {
  SquadronException(this.message);

  /// Message (or string representation of the exception).
  final String message;

  @override
  String toString() => 'SquadronException: $message';
}
