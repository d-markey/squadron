import 'dart:async';
import 'dart:isolate';

import '../channel.dart';
import '../worker_exception.dart';
import '../worker_request.dart';
import '../worker_response.dart';

/// [Channel] implementation for the native world.
class VmChannel implements Channel {
  /// [SendPort] to communicate with the [Isolate] if the channel is owned by the worker owner.
  /// Otherwise, [SendPort] to return values to the client.
  SendPort? _sendPort;

  /// [Channel] serialization in native world returns the [SendPort].
  @override
  dynamic serialize() => _sendPort;

  /// [Channel] sharing in native world returns the same instance.
  @override
  Channel share() => this;

  /// Sends the [SendPort] to communicate with the [Isolate].
  /// This method must be called by the [Isolate] upon startup.
  @override
  void connect(Object channelInfo) {
    if (channelInfo is ReceivePort) {
      _sendPort!.send(channelInfo.sendPort);
    } else if (channelInfo is SendPort) {
      _sendPort!.send(channelInfo);
    } else {
      throw WorkerException(
          'Invalid channelInfo $channelInfo; expected ReceivePort or SendPort');
    }
  }

  /// Sends a termination [WorkerRequest] to the [Isolate] and clears the [SendPort].
  @override
  FutureOr close() {
    if (_sendPort != null) {
      _sendPort?.send(WorkerRequest.terminate().serialize());
      _sendPort = null;
    }
  }

  /// creates a [ReceivePort] and a [WorkerRequest] and sends it to the [Isolate]
  /// this method expects a single value from the [Isolate]
  @override
  Future<T> sendRequest<T>(int command, List args) async {
    final receiver = ReceivePort();
    _sendPort!
        .send(WorkerRequest(receiver.sendPort, command, args).serialize());
    final res = WorkerResponse.deserialize(await receiver.first);
    return res.result as T;
  }

  /// Creates a [ReceivePort] and a [WorkerRequest] and sends it to the [Isolate].
  /// This method expects a stream of values from the [Isolate].
  /// The [Isolate] must send a [WorkerResponse.endOfStream] to close the [Stream].
  @override
  Stream<T> sendStreamingRequest<T>(int command, List args) async* {
    final receiver = ReceivePort();
    _sendPort!
        .send(WorkerRequest(receiver.sendPort, command, args).serialize());
    await for (var item in receiver) {
      final res = WorkerResponse.deserialize(item);
      if (res.endOfStream) break;
      yield res.result as T;
    }
  }

  /// Sends the [WorkerResponse] to the worker client.
  /// This method must be called from the [Isolate] only.
  @override
  void reply(WorkerResponse response) {
    _sendPort?.send(response.serialize());
  }
}

/// Starts an [Isolate] using the [entryPoint] and sends a start [WorkerRequest] with [startArguments].
/// The future completes after the [Isolate]'s main program has provided the [SendPort] via [VmChannel.connect].
Future<Channel> _openChannel(dynamic entryPoint, List startArguments) async {
  final channel = VmChannel();
  final receiver = ReceivePort();
  await Isolate.spawn(entryPoint,
      WorkerRequest.start(receiver.sendPort, startArguments).serialize());
  channel._sendPort = await receiver.first;
  return channel;
}

/// Creates a [VmChannel] from a [SendPort].
/// To be used in the [Isolate] when the [WorkerRequest] includes a [Channel].
Channel? _deserializeChannel(dynamic channelInfo) {
  if (channelInfo == null) return null;
  final channel = VmChannel();
  channel._sendPort = channelInfo;
  return channel;
}

/// Stub implementations.
Future<Channel> Function(dynamic entryPoint, List startArguments)
    get openChannel => _openChannel;

Channel? Function(dynamic channelInfo) get deserializeChannel =>
    _deserializeChannel;
