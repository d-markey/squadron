import 'dart:async';

import 'package:cancelation_token/cancelation_token.dart';

import '../channel.dart';
import '../tokens/_squadron_cancelation_token.dart';
import '../worker/worker_request.dart';
import '../worker_service.dart';
import 'local_worker.dart';

/// Base class used to communicate with a [LocalWorker].
///
/// Typically, derived classes should add proxy methods sending [WorkerRequest]s to the worker.
class LocalWorkerClient implements WorkerService {
  /// Create a client for a [LocalWorker]. The [channel] passed to this client must have been obtained by
  /// calling [Channel.share] on the [LocalWorker.channel].
  LocalWorkerClient(this.channel);

  /// The [Channel] to communicate with the [LocalWorker].
  final Channel channel;

  /// Sends a command to the [LocalWorker].
  Future<T> send<T>(int command,
          {List args = const [],
          CancelationToken? token,
          bool inspectRequest = false,
          bool inspectResponse = false}) =>
      channel.sendRequest<T>(command, args,
          token: channel.wrap(token),
          inspectRequest: inspectRequest,
          inspectResponse: inspectResponse);

  /// Sends a streaming command to the [LocalWorker].
  Stream<T> stream<T>(int command,
          {List args = const [],
          CancelationToken? token,
          bool inspectRequest = false,
          bool inspectResponse = false}) =>
      channel.sendStreamingRequest<T>(command, args,
          onDone: Channel.noop,
          token: channel.wrap(token),
          inspectRequest: inspectRequest,
          inspectResponse: inspectResponse);

  /// Local worker clients do not need an [operations] map.
  @override
  final Map<int, CommandHandler> operations = WorkerService.noOperations;
}
