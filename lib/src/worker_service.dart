import 'dart:async';

import 'worker_request.dart';

typedef WorkerInitializer = FutureOr<WorkerService> Function(
    WorkerRequest startRequest);

typedef CommandHandler = FutureOr Function(WorkerRequest req);

typedef SquadronCallback = void Function();

/// Base class for a worker service.
abstract class WorkerService {
  /// Map of command handlers. Upon reception of a [WorkerRequest], the platform worker will dispatch the request
  /// to the [CommandHandler] mathing the value of [WorkerRequest.command].
  Map<int, CommandHandler> get operations;
}
