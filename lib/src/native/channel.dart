import 'dart:async';
import 'dart:isolate';

import '../cancellation_token.dart';
import '../channel.dart' show Channel, WorkerChannel;
import '../squadron.dart';
import '../worker_exception.dart';
import '../worker_request.dart';
import '../worker_response.dart';

class _SendPort {
  /// [SendPort] to communicate with the [Isolate] if the channel is owned by the worker owner.
  /// Otherwise, [SendPort] to return values to the client.
  SendPort? _sendPort;

  /// [Channel] serialization in JavaScript world returns the [web.MessagePort].
  dynamic serialize() => _sendPort;
}

/// [Channel] implementation for the native world.
class VmChannel extends _SendPort implements Channel {
  /// [Channel] sharing in native world returns the same instance.
  @override
  Channel share() => this;

  /// Sends a termination [WorkerRequest] to the [Isolate] and clears the [SendPort].
  @override
  FutureOr close() {
    if (_sendPort != null) {
      _sendPort?.send(WorkerRequest.stop().serialize());
      _sendPort = null;
    }
  }

  /// Creates a [web.MessageChannel] and a [WorkerRequest] and sends it to the [web.Worker].
  /// This method expects a single value from the [web.Worker].
  @override
  void cancelToken(CancellationToken token) {
    if (token.cancelled) {
      _sendPort!.send(WorkerRequest.cancel(token).serialize());
    }
  }

  /// creates a [ReceivePort] and a [WorkerRequest] and sends it to the [Isolate]
  /// this method expects a single value from the [Isolate]
  @override
  Future<T> sendRequest<T>(int command, List args,
      {CancellationToken? token}) async {
    final receiver = ReceivePort();
    _sendPort!.send(
        WorkerRequest(receiver.sendPort, command, args, token).serialize());
    final res = WorkerResponse.deserialize(await receiver.first);
    return res.result as T;
  }

  /// Creates a [ReceivePort] and a [WorkerRequest] and sends it to the [Isolate].
  /// This method expects a stream of values from the [Isolate].
  /// The [Isolate] must send a [WorkerResponse.endOfStream] to close the [Stream].
  @override
  Stream<T> sendStreamingRequest<T>(int command, List args,
      {CancellationToken? token}) async* {
    final receiver = ReceivePort();
    _sendPort!.send(
        WorkerRequest(receiver.sendPort, command, args, token).serialize());
    await for (var item in receiver) {
      final res = WorkerResponse.deserialize(item);
      if (res.endOfStream) break;
      yield res.result as T;
    }
  }
}

/// [WorkerChannel] implementation for the native world.
class VmWorkerChannel extends _SendPort implements WorkerChannel {
  /// Sends the [SendPort] to communicate with the [Isolate].
  /// This method must be called by the [Isolate] upon startup.
  @override
  void connect(Object channelInfo) {
    try {
      if (channelInfo is ReceivePort) {
        _sendPort!.send(WorkerResponse(channelInfo.sendPort).serialize());
      } else if (channelInfo is SendPort) {
        _sendPort!.send(WorkerResponse(channelInfo).serialize());
      } else {
        throw WorkerException(
            'Invalid channelInfo ${channelInfo.runtimeType}; expected ReceivePort or SendPort');
      }
    } catch (ex) {
      Squadron.severe('Failed to post connection response: $ex');
      rethrow;
    }
  }

  /// Sends the [WorkerResponse] to the worker client.
  /// This method must be called from the [Isolate] only.
  @override
  void reply(WorkerResponse response) {
    if (response.hasError) {
      Squadron.fine('replying with error: ${response.error}');
    }
    _sendPort?.send(response.serialize());
  }
}

/// Stub implementations.

int _counter = 0;
String _getId() {
  _counter++;
  return '${Squadron.id}.$_counter';
}

/// Starts an [Isolate] using the [entryPoint] and sends a start [WorkerRequest] with [startArguments].
/// The future completes after the [Isolate]'s main program has provided the [SendPort] via [VmWorkerChannel.connect].
Future<Channel> openChannel(dynamic entryPoint, List startArguments) async {
  final channel = VmChannel();
  final receiver = ReceivePort();
  final isolate = await Isolate.spawn(
      entryPoint,
      WorkerRequest.start(receiver.sendPort, _getId(), startArguments)
          .serialize());
  Squadron.config('created Isolate #${isolate.hashCode}');
  final response = WorkerResponse.deserialize(await receiver.first);
  if (response.hasError) {
    isolate.kill(priority: Isolate.immediate);
    Squadron.severe(
        'connection to Isolate #${isolate.hashCode} failed: ${response.error}');
    throw response.exception;
  } else {
    channel._sendPort = response.result;
    Squadron.config('connected to Isolate #${isolate.hashCode}');
    return channel;
  }
}

/// Creates a [VmChannel] from a [SendPort].
Channel? deserializeChannel(dynamic channelInfo) =>
    channelInfo == null ? null : (VmChannel().._sendPort = channelInfo);

/// Creates a [VmWorkerChannel] from a [SendPort].
WorkerChannel? deserializeWorkerChannel(dynamic channelInfo) =>
    channelInfo == null ? null : (VmWorkerChannel().._sendPort = channelInfo);
