import 'dart:async';

import 'package:squadron/squadron.dart';

import 'channel_stub.dart'
    if (dart.library.js) 'browser/channel.dart'
    if (dart.library.html) 'browser/channel.dart'
    if (dart.library.io) 'native/channel.dart';

abstract class Channel {
  /// [Channel] serialization
  /// return an opaque object that can be transfered from the client to the worker
  dynamic serialize();

  /// [Channel] sharing
  /// return a [Channel] that can be provided to enable another worker to call the channel's worker
  Channel share();

  /// connects the [Channel] with the Squadron [Worker]
  /// [channelInfo] is an opaque object than can be deserialized as a [Channel]
  /// this method must be called by the worker upon startup
  void connect(Object channelInfo);

  /// sends a termination [WorkerRequest] to the worker
  /// the [Channel] should release any resource related to the worker and should not be useable after calling this method
  FutureOr close();

  /// creates a [WorkerRequest] and sends it to the worker
  /// this method expects a single value from the worker
  Future<T> sendRequest<T>(int command, List args);

  /// creates a [WorkerRequest] and sends it to the worker
  /// this method expects a stream of values from the worker
  /// the worker must send a [WorkerResponse.endOfStream] to close the [Stream]
  Stream<T> sendStreamingRequest<T>(int command, List args);

  /// sends the [WorkerResponse] to the worker client
  /// this method must be called from the worker only
  void reply(WorkerResponse data);

  /// starts a worker using the [entryPoint] and sends a start [WorkerRequest] with [startArguments]
  /// the future must not complete before the worker is ready to serve requests
  static Future<Channel> open(dynamic entryPoint, List startArguments) =>
      openChannel(entryPoint, startArguments);

  /// deserializes a [Channel] from an opaque [channelInfo]
  static Channel? deserialize(dynamic channelInfo) =>
      deserializeChannel(channelInfo);
}
