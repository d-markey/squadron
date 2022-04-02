import '_local_worker_stub.dart'
    if (dart.library.js) 'browser/_local_worker.dart'
    if (dart.library.html) 'browser/_local_worker.dart'
    if (dart.library.io) 'native/_local_worker.dart';

import 'channel.dart';
import 'worker_request.dart';
import 'worker_service.dart';

/// Base local worker class.
///
/// Local workers are similar to other Workers except that they run in the context of the current thread.
/// They do not create any platform thread (such as Isolate or Web Worker) but they provide a [channel] that
/// can be shared with other workers to support communication between threads. One interesting use-case is
/// accessing UI components or platform plugins in Flutter, where only code running in the main thread is
/// allowed access to such features. Creating a [LocalWorker] in the main application and sharing its
/// [channel] with other workers enables providing access to Flutter features.
///
/// Local workers wrap around a [WorkerService]. Messages sent to the local worker are deserialized as
/// [WorkerRequest] and dispatched to a handler defined in the [service]'s [WorkerService.operations] map
/// according to the [WorkerRequest.command].
abstract class LocalWorker<W extends WorkerService> implements WorkerService {
  LocalWorker(this.service);

  factory LocalWorker.create(W service) => createLocalWorker<W>(service);

  /// The [WorkerService] associated to this local worker.
  final W service;

  /// The local worker's [Channel]. This channel can be shared with other workers by calling [Channel.share].
  Channel? get channel;

  /// Stops the local worker.
  void stop();

  /// Local Workers do not need an [operations] map.
  @override
  final Map<int, CommandHandler> operations = WorkerService.noOperations;
}