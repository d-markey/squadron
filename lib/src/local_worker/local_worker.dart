import 'dart:async';

import 'package:using/using.dart';

import '../../squadron.dart';
import '../_impl/xplat/_local_worker.dart'
    if (dart.library.io) '../_impl/native/_local_worker.dart'
    if (dart.library.html) '../_impl/web/_local_worker.dart'
    if (dart.library.js) '../_impl/web/_local_worker.dart'
    if (dart.library.js_interop) '../_impl/web/_local_worker.dart' as impl;

/// Base local worker class.
///
/// Local workers are similar to other Workers except that they run in the
/// context of the current thread. They do not create any platform thread
/// (such as Isolate or Web Worker) but they provide a [channel] that can be
/// shared with other workers to support communication between threads. One
/// interesting use-case is accessing UI components or platform plugins in
/// Flutter, where only code running in the main thread is allowed access to
/// such features. Creating a [LocalWorker] in the main application and sharing
/// its [channel] with other workers enables providing access to Flutter
/// features.
///
/// Local workers wrap around a [WorkerService]. Messages sent to the local
/// worker are deserialized as [WorkerRequest]s and dispatched to a handler
/// defined in the [_service]'s [WorkerService.operations] map according to the
/// [WorkerRequest.command].
abstract interface class LocalWorker<W>
    with Releasable
    implements WorkerService, IWorker {
  factory LocalWorker.create(W service,
      [OperationsMap? operations, ExceptionManager? exceptionManager]) {
    if (operations == null) {
      if (service is WorkerService) {
        operations = service.operations;
      } else {
        throw ArgumentError(
          'The operations map must be provided because $W does not implement $WorkerService',
          'operations',
        );
      }
    }
    return impl.createLocalWorker<W>(
      service,
      operations,
      exceptionManager ?? ExceptionManager(),
    );
  }

  W get service;

  @override
  ExceptionManager get exceptionManager;

  /// The local worker's [Channel].
  Channel? get channel;

  /// Starts the local worker.
  @override
  FutureOr<void> start();

  /// Stops the local worker.
  @override
  void stop();

  /// Terminates the local worker.
  @override
  void terminate([TaskTerminatedException? ex]);

  /// Forward to underlying service.
  @override
  OperationsMap get operations;
}
