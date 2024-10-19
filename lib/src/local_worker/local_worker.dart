import 'dart:async';

import 'package:logger/web.dart';
import 'package:using/using.dart';

import '../_impl/xplat/_local_worker.dart'
    if (dart.library.io) '../_impl/native/_local_worker.dart'
    if (dart.library.html) '../_impl/web/_local_worker.dart'
    if (dart.library.js_interop) '../_impl/web/_local_worker.dart' as impl;
import '../channel.dart';
import '../exceptions/exception_manager.dart';
import '../iworker.dart';
import '../worker/worker_request.dart';
import '../worker_service.dart';

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
abstract base class LocalWorker<W extends WorkerService>
    with Releasable
    implements WorkerService, IWorker {
  LocalWorker(this._service);

  factory LocalWorker.create(W service, [ExceptionManager? exceptionManager]) =>
      impl.createLocalWorker<W>(
          service, exceptionManager ?? ExceptionManager());

  final W _service;

  @override
  void release() {
    stop();
    super.release();
  }

  @override
  Logger? channelLogger;

  @override
  ExceptionManager get exceptionManager =>
      (_exceptionManager ??= ExceptionManager());
  ExceptionManager? _exceptionManager;

  /// The local worker's [Channel].
  Channel? get channel;

  /// A [Channel] to communicate with this local worker. This channel should be
  /// provided to clients so they can invoke services from the local worker.
  Channel? get sharedChannel => channel?.share();

  /// Starts the local worker.
  @override
  FutureOr<void> start();

  /// Stops the local worker.
  @override
  void stop();

  /// Forward to underlying service.
  @override
  Map<int, CommandHandler> get operations => _service.operations;
}
