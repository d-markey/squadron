import 'dart:async';

import 'channel_stub.dart'
    if (dart.library.js) 'browser/channel.dart'
    if (dart.library.html) 'browser/channel.dart'
    if (dart.library.io) 'native/channel.dart';

import 'worker_response.dart';

/// A [Channel] supports communication from a client to a platform worker.
/// It is used to send a [WorkerRequest] to a platform worker.
abstract class Channel {
  /// [Channel] serialization.
  /// Returns an opaque object that can be transfered from the client to the worker.
  dynamic serialize();

  /// [Channel] sharing.
  /// Returns a [Channel] object that can be provided to enable another worker to call the channel's worker.
  Channel share();

  /// Sends a termination [WorkerRequest] to the worker.
  /// The [Channel] should release any resource related to the worker and should not be used after this method has been called.
  FutureOr close();

  /// Creates a [WorkerRequest] and sends it to the worker.
  /// This method expects a single value from the worker.
  Future<T> sendRequest<T>(int command, List args);

  /// Creates a [WorkerRequest] and sends it to the worker.
  /// This method expects a stream of values from the worker.
  /// The worker must send a [WorkerResponse.closeStream] message to close the [Stream].
  Stream<T> sendStreamingRequest<T>(int command, List args);

  /// Starts a worker using the [entryPoint] and sends a start [WorkerRequest] with [startArguments].
  /// The future must not complete before the worker is ready to serve requests.
  static Future<Channel> open(dynamic entryPoint, List startArguments) =>
      openChannel(entryPoint, startArguments);

  /// Deserializes a [Channel] from an opaque [channelInfo].
  static Channel? deserialize(dynamic channelInfo) =>
      deserializeChannel(channelInfo);
}

/// A [WorkerChannel] supports communication from a platform worker to the client that posted the [WorkerRequest].
/// It is used to send [WorkerResponse] back to the client.
abstract class WorkerChannel {
  /// [WorkerChannel] serialization.
  /// Returns an opaque object that can be transfered from the client to the worker.
  dynamic serialize();

  /// Connects the [Channel] with the Squadron [Worker].
  /// [channelInfo] is an opaque object than can be deserialized as a [Channel].
  /// This method must be called by the worker upon startup.
  void connect(Object channelInfo);

  /// Sends the [WorkerResponse] to the worker client.
  /// This method must be called from the worker only.
  void reply(WorkerResponse data);

  /// Deserializes a [Channel] from an opaque [channelInfo].
  static WorkerChannel? deserialize(dynamic channelInfo) =>
      deserializeWorkerChannel(channelInfo);
}
