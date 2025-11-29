import 'typedefs.dart';
import 'worker/worker_request.dart';

/// Base class for a worker service.
abstract interface class WorkerService {
  /// Map of command handlers. Upon reception of a [WorkerRequest], the platform
  /// worker will dispatch the request to the [CommandHandler] matching the value
  /// of [WorkerRequest.command].
  OperationsMap get operations;

  /// Empty command handlers map.
  static const OperationsMap noOperations = OperationsMap({});
}
