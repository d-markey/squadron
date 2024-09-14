import 'dart:async';

import 'package:cancelation_token/cancelation_token.dart';
import 'package:using/using.dart';

import '../channel.dart';
import '../tokens/_squadron_cancelation_token.dart';
import '../worker/worker_request.dart';
import '../worker_service.dart';
import 'local_worker.dart';

/// Base class used to communicate with a [LocalWorker].
///
/// Typically, derived classes should add proxy methods sending [WorkerRequest]s to the worker.
class LocalWorkerClient with Releasable implements WorkerService {
  /// Create a client for a [LocalWorker]. The [channel] passed to this client must have been obtained by
  /// calling [Channel.share] on the [LocalWorker.channel].
  LocalWorkerClient(this.channel);

  /// The [Channel] to communicate with the [LocalWorker].
  final Channel channel;

  @override
  void release() {
    channel.close();
    super.release();
  }

  /// Sends a command to the [LocalWorker].
  Future<dynamic> send(int command,
          {List args = const [],
          SquadronCancelationToken? token,
          bool inspectRequest = false,
          bool inspectResponse = false}) =>
      channel.sendRequest(command, args,
          token: token?.wrap(),
          inspectRequest: inspectRequest,
          inspectResponse: inspectResponse);

  /// Sends a streaming command to the [LocalWorker].
  Stream<dynamic> stream(int command,
          {List args = const [],
          CancelationToken? token,
          bool inspectRequest = false,
          bool inspectResponse = false}) =>
      channel.sendStreamingRequest(command, args,
          token: token?.wrap(),
          inspectRequest: inspectRequest,
          inspectResponse: inspectResponse);

  /// Local worker clients do not need an [operations] map.
  @override
  final Map<int, CommandHandler> operations = WorkerService.noOperations;
}
