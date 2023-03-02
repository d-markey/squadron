import '../squadron_logger.dart';

/// Annotation used to indicate the type of a logger to be used in worker threads.
/// Package `squadron_builder` will register the provided [logger] when initializing
/// the worker thread.
class UseLogger {
  const UseLogger(this.logger);

  /// Type or constant instance of the logger to use in the worker thread.
  /// The type or instance type must implement [SquadronLogger].
  final dynamic logger;
}
