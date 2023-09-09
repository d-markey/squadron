import 'dart:async';

import '_impl/xplat/_channel.dart'
    if (dart.library.io) '_impl/native/_channel.dart'
    if (dart.library.js) '_impl/browser/_channel.dart'
    if (dart.library.html) '_impl/browser/_channel.dart';
import 'tokens/cancellation_token.dart';
import 'worker/worker_request.dart';
import 'worker/worker_response.dart';
import 'worker/worker_service.dart';

/// A [Channel] supports communication from a client to a platform worker. It is used to send a [WorkerRequest] to
/// a platform worker.
abstract class Channel {
  /// The ID of the worker attached to this [Channel].
  String get workerId;

  /// [Channel] serialization. Returns an opaque object that can be transfered from the client to the worker.
  dynamic serialize();

  /// [Channel] sharing. Returns a [Channel] object that can be provided to enable another worker to call the
  /// channel's worker.
  Channel share();

  /// Sends a termination [WorkerRequest] to the worker. The [Channel] should release any resource related to the
  /// worker and should not be used after this method has been called.
  FutureOr close();

  /// Static method that does nothing. Useful when a [SquadronCallback] is required but there is nothing to do.
  static void noop() {}

  /// Creates a [WorkerRequest] and sends it to the worker. This method expects a single value from the worker.
  Future<T> sendRequest<T>(int command, List args,
      {CancellationToken? token,
      bool inspectRequest = false,
      bool inspectResponse = false});

  /// Creates a [WorkerRequest] and sends it to the worker. This method expects a stream of values from the worker.
  /// The worker must send a [WorkerResponse.closeStream] message to close the [Stream].
  Stream<T> sendStreamingRequest<T>(int command, List args,
      {SquadronCallback onDone = Channel.noop,
      CancellationToken? token,
      bool inspectRequest = false,
      bool inspectResponse = false});

  /// Starts a worker using the [entryPoint] and sends a start [WorkerRequest] with [startArguments]. The future
  /// must not complete before the worker is ready to serve requests.
  static Future<Channel> open(
          EntryPoint entryPoint, String workerId, List startArguments,
          [PlatformWorkerHook? hook]) =>
      openChannel(entryPoint, workerId, startArguments, hook);

  /// Deserializes a [Channel] from an opaque [channelInfo].
  static Channel? deserialize(dynamic channelInfo) =>
      deserializeChannel(channelInfo);
}
