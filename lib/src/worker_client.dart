import 'dart:async';

import 'package:cancelation_token/cancelation_token.dart';
import 'package:using/using.dart';

import 'channel.dart';
import 'invoker.dart';
import 'tokens/_squadron_cancelation_token.dart';
import 'typedefs.dart';
import 'worker/worker.dart';
import 'worker/worker_request.dart';
import 'worker_service.dart';

@Deprecated('Use WorkerClient instead.')
typedef LocalWorkerClient = WorkerClient;

/// Base class used to communicate with a [Worker] over a [Channel].
///
/// Typically, derived classes should add proxy methods sending [WorkerRequest]s to the worker.
class WorkerClient with Releasable implements WorkerService, Invoker {
  /// Create a client for a [Worker]. The [channel] passed to this client must have been obtained
  /// from the target [Worker].
  WorkerClient(this.channel);

  /// The [Channel] to communicate with the [Worker].
  final Channel channel;

  @override
  void release() {
    channel.close();
    super.release();
  }

  /// Sends a command to the [Worker].
  @override
  Future<dynamic> send(int command,
          {List args = const [],
          CancelationToken? token,
          bool inspectRequest = false,
          bool inspectResponse = false}) =>
      channel.sendRequest(command, args,
          token: token?.wrap(),
          inspectRequest: inspectRequest,
          inspectResponse: inspectResponse);

  /// Sends a streaming command to the [Worker].
  @override
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
  final OperationsMap operations = WorkerService.noOperations;
}
