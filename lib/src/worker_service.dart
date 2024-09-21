import 'dart:async';

import 'worker/worker.dart';
import 'worker/worker_request.dart';

typedef WorkerInitializer = FutureOr<WorkerService> Function(
    WorkerRequest startRequest);

typedef CommandHandler = FutureOr<dynamic> Function(WorkerRequest req);

typedef SquadronCallback = void Function();
typedef SquadronAsyncCallback = FutureOr<void> Function();

/// Extend this class or implement this interface in your worker service if it needs
/// to take action when the worker thread is started or stopped.
mixin ServiceInstaller {
  /// Squadron will call this method as part of the worker thread initialization.
  /// It will be called just after the service instance has been constructed. The
  /// future returned by [Worker.start] will not complete before this method completes
  /// whether synchronously or asynchronously. If this method throws, the future
  /// returned by [Worker.start] will complete with an error and the service will not
  /// be available.
  FutureOr<void> install() {}

  /// Squadron will call this method as part of the worker thread shutdown process.
  /// It will be called just before effectively closing the platform channel. If
  /// this method throws, the exception will not bubble up to the parent thread.
  /// Also, [Worker.stop] does not wait for this method to complete.
  FutureOr<void> uninstall() {}
}

/// Base class for a worker service.
abstract interface class WorkerService {
  /// Map of command handlers. Upon reception of a [WorkerRequest], the platform
  /// worker will dispatch the request to the [CommandHandler] mathing the value
  /// of [WorkerRequest.command].
  Map<int, CommandHandler> get operations;

  /// Empty command handlers map.
  static final Map<int, CommandHandler> noOperations =
      Map<int, CommandHandler>.unmodifiable(const {});
}
