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

  /// [Channel] serialization in Native world returns the [SendPort].
  dynamic serialize() => _sendPort;

  void _postRequest(WorkerRequest req) {
    final message = req.serialize();
    try {
      _sendPort!.send(message);
    } catch (ex) {
      Squadron.severe('Failed to post request message: $ex');
      Squadron.severe('   message is $message');
      rethrow;
    }
  }

  void _postResponse(WorkerResponse res) {
    final message = res.serialize();
    try {
      _sendPort!.send(message);
    } catch (ex) {
      Squadron.severe('Failed to post response message: $ex');
      Squadron.severe('   message is $message');
      rethrow;
    }
  }
}

/// [Channel] implementation for the Native world.
class _VmChannel extends _SendPort implements Channel {
  _VmChannel._();

  /// [Channel] sharing in Native world returns the same instance.
  @override
  Channel share() => this;

  /// Sends a termination [WorkerRequest] to the [Isolate] and clears the [SendPort].
  @override
  FutureOr close() {
    if (_sendPort != null) {
      _postRequest(WorkerRequest.stop());
      _sendPort = null;
    }
  }

  /// Creates a [web.MessageChannel] and a [WorkerRequest] and sends it to the [web.Worker].
  /// This method expects a single value from the [web.Worker].
  @override
  void notifyCancellation(CancellationToken token) {
    if (token.cancelled) {
      _postRequest(WorkerRequest.cancel(token));
    }
  }

  /// creates a [ReceivePort] and a [WorkerRequest] and sends it to the [Isolate]
  /// this method expects a single value from the [Isolate]
  @override
  Future<T> sendRequest<T>(int command, List args,
      {CancellationToken? token}) async {
    final receiver = ReceivePort();
    _postRequest(WorkerRequest(receiver.sendPort, command, args, token));
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
    _postRequest(WorkerRequest(receiver.sendPort, command, args, token));
    await for (var item in receiver) {
      final res = WorkerResponse.deserialize(item);
      if (res.endOfStream) break;
      yield res.result as T;
    }
  }
}

/// [WorkerChannel] implementation for the native world.
class _VmWorkerChannel extends _SendPort implements WorkerChannel {
  _VmWorkerChannel._();

  /// Sends the [SendPort] to communicate with the [Isolate].
  /// This method must be called by the [Isolate] upon startup.
  @override
  void connect(Object channelInfo) {
    if (channelInfo is ReceivePort) {
      _postResponse(WorkerResponse(channelInfo.sendPort));
    } else if (channelInfo is SendPort) {
      _postResponse(WorkerResponse(channelInfo));
    } else {
      throw WorkerException(
          'Invalid channelInfo ${channelInfo.runtimeType}; expected ReceivePort or SendPort');
    }
  }

  /// Sends the [WorkerResponse] to the worker client.
  /// This method must be called from the [Isolate] only.
  @override
  void reply(WorkerResponse response) {
    if (response.hasError) {
      Squadron.finer('replying with error: ${response.error}');
    }
    _postResponse(response);
  }
}

/// Stub implementations.

int _counter = 0;
String _getId() {
  _counter++;
  return '${Squadron.id}.$_counter';
}

/// Starts an [Isolate] using the [entryPoint] and sends a start [WorkerRequest] with [startArguments].
/// The future completes after the [Isolate]'s main program has provided the [SendPort] via [_VmWorkerChannel.connect].
Future<Channel> openChannel(dynamic entryPoint, List startArguments) async {
  final channel = _VmChannel._();
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

/// Creates a [_VmChannel] from a [SendPort].
Channel? deserializeChannel(dynamic channelInfo) =>
    channelInfo == null ? null : (_VmChannel._().._sendPort = channelInfo);

/// Creates a [_VmWorkerChannel] from a [SendPort].
WorkerChannel? deserializeWorkerChannel(dynamic channelInfo) =>
    channelInfo == null
        ? null
        : (_VmWorkerChannel._().._sendPort = channelInfo);
