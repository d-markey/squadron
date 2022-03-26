import 'dart:async';

import '_local_worker_stub.dart'
    if (dart.library.js) 'browser/local_worker.dart'
    if (dart.library.html) 'browser/local_worker.dart'
    if (dart.library.io) 'native/local_worker.dart';

import 'channel.dart';
import 'squadron.dart';
import 'squadron_exception.dart';
import 'worker_request.dart';
import 'worker_response.dart';
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

  /// Deserializes the [WorkerRequest] from [message] and passes it to the underlying [service] for processing.
  /// The request handler is located via the [WorkerService.operations] map based on [WorkerRequest.command].
  /// If processing succeeds, the result is sent back to the client. If an error occurs, it is sent back to
  /// the client.
  void _process(dynamic message) {
    WorkerRequest request;
    try {
      request = WorkerRequest.deserialize(message);
    } catch (ex) {
      Squadron.config(
          'Received invalid message ${message.runtimeType}: $message');
      return;
    }
    final client = request.client;
    if (client == null) {
      Squadron.config('Client is null');
      return;
    }
    dynamic result;
    try {
      final handler = service.operations[request.command];
      if (handler != null) {
        result = handler(request);
      } else {
        throw SquadronException('Unsupported command ${request.command}');
      }
    } catch (ex, st) {
      client.reply(WorkerResponse.withError(ex, st.toString()));
      return;
    }
    if (result is Future) {
      result.then((value) => client.reply(WorkerResponse(value))).onError(
          (ex, st) =>
              client.reply(WorkerResponse.withError(ex, st.toString())));
    } else {
      client.reply(WorkerResponse(result));
    }
  }

  /// The local worker's [Channel]. This channel can be shared with other workers by calling [Channel.share].
  Channel? get channel;

  /// Stops the local worker.
  void stop();

  /// Local Workers do not need an [operations] map.
  @override
  final Map<int, CommandHandler> operations = WorkerService.noOperations;
}

void processMessage(LocalWorker w, dynamic message) => w._process(message);
