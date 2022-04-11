import 'dart:async';
import 'dart:isolate';

import '../_stream_wrapper.dart';
import '../cancellation_token.dart';
import '../channel.dart' show Channel, WorkerChannel;
import '../squadron.dart';
import '../squadron_exception.dart';
import '../worker_exception.dart';
import '../worker_request.dart';
import '../worker_response.dart';
import '../worker_service.dart';

class _SendPort {
  /// [SendPort] to communicate with the [Isolate] if the channel is owned by the worker owner. Otherwise, [SendPort]
  /// to return values to the client.
  SendPort? _sendPort;

  /// [Channel] serialization in Native world returns the [SendPort].
  dynamic serialize() => _sendPort;

  void _postRequest(WorkerRequest req) {
    req.cancelToken?.ensureStarted();
    final message = req.serialize();
    try {
      _sendPort?.send(message);
    } catch (ex) {
      Squadron.severe('failed to post request $message: error $ex');
      rethrow;
    }
  }

  void _postResponse(WorkerResponse res) {
    final message = res.serialize();
    try {
      _sendPort!.send(message);
    } catch (ex) {
      Squadron.severe('failed to post response $message: error $ex');
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

  /// If the [token] is cancelled, sends a [WorkerRequest.cancel] message to signal the worker that the token is
  /// cancelled.
  @override
  void notifyCancellation(CancellationToken token) {
    if (token.cancelled) {
      _postRequest(WorkerRequest.cancel(token));
    }
  }

  /// creates a [ReceivePort] and a [WorkerRequest] and sends it to the [Isolate]. This method expects a single
  /// value from the [Isolate]
  @override
  Future<T> sendRequest<T>(int command, List args,
      {CancellationToken? token}) async {
    final receiver = ReceivePort();
    _postRequest(WorkerRequest(receiver.sendPort, command, args, token));
    final res = WorkerResponse.deserialize(await receiver.first);
    return res.result as T;
  }

  /// Creates a [ReceivePort] and a [WorkerRequest] and sends it to the [Isolate]. This method expects a stream of
  /// values from the [Isolate]. The [Isolate] must send a [WorkerResponse.endOfStream] to close the [Stream].
  @override
  Stream<T> sendStreamingRequest<T>(int command, List args,
      {SquadronCallback onDone = Channel.noop, CancellationToken? token}) {
    final receiver = ReceivePort();
    final req = WorkerRequest(receiver.sendPort, command, args, token);
    final wrapper = StreamWrapper<T>(
      () => _postRequest(req),
      receiver,
      () {
        receiver.close();
        onDone();
      },
      token,
    );

    return wrapper.stream;
  }
}

/// [WorkerChannel] implementation for the native world.
class _VmWorkerChannel extends _SendPort implements WorkerChannel {
  _VmWorkerChannel._();

  /// Sends the [SendPort] to communicate with the [Isolate]. This method must be called by the [Isolate] upon
  /// startup.
  @override
  void connect(Object channelInfo) {
    if (channelInfo is ReceivePort) {
      reply(channelInfo.sendPort);
    } else {
      throw WorkerException(
          'invalid channelInfo ${channelInfo.runtimeType}: ReceivePort expected');
    }
  }

  /// Sends a [WorkerResponse] with the specified data to the worker client. This method must be called from the
  /// [Isolate] only.
  @override
  void reply(dynamic data) => _postResponse(WorkerResponse(data));

  /// Checks if [stream] can be streamed back to the worker client. Returns `true` unless [stream] is a
  /// [ReceivePort].
  @override
  bool canStream(Stream stream) => stream is! ReceivePort;

  /// Sends a [WorkerResponse.closeStream] to the worker client. This method must be called from the [Isolate] only.
  @override
  void closeStream() => _postResponse(WorkerResponse.closeStream);

  /// Sends the [WorkerException] to the worker client. This method must be called from the [Isolate] only.
  @override
  void error(SquadronException error) {
    Squadron.finer('replying with error: $error');
    _postResponse(WorkerResponse.withError(error));
  }
}

/// Stub implementations.

int _counter = 0;
String _getId() {
  _counter++;
  return '${Squadron.id}.$_counter';
}

/// Starts an [Isolate] using the [entryPoint] and sends a start [WorkerRequest] with [startArguments]. The future
/// completes after the [Isolate]'s main program has provided the [SendPort] via [_VmWorkerChannel.connect].
Future<Channel> openChannel(dynamic entryPoint, List startArguments) async {
  final completer = Completer<Channel>();
  final channel = _VmChannel._();
  final receiver = ReceivePort();
  Isolate.spawn(
          entryPoint,
          WorkerRequest.start(receiver.sendPort, _getId(), startArguments)
              .serialize(),
          paused: true)
      .then((isolate) {
    final exitPort = ReceivePort();
    exitPort.listen((message) {
      channel.close();
    });
    isolate.addOnExitListener(exitPort.sendPort);
    final errorPort = ReceivePort();
    errorPort.listen((message) {
      dynamic error = message[0];
      if (error is String) {
        error = SquadronException.fromString(error);
      }
      if (error is! SquadronException) {
        error = SquadronException.from(
            error: message[0] ?? 'unspecified error',
            stackTrace: SquadronException.loadStackTrace(message[1]));
      }
      if (!completer.isCompleted) {
        completer.completeError(error);
      } else {
        Squadron.warning('unhandled error $error');
      }
    });
    isolate.addErrorListener(errorPort.sendPort);
    isolate.resume(isolate.pauseCapability!);
    Squadron.config('created Isolate #${isolate.hashCode}');
    receiver.first.then((message) {
      final response = WorkerResponse.deserialize(message);
      if (!completer.isCompleted) {
        if (response.hasError) {
          isolate.kill(priority: Isolate.immediate);
          Squadron.severe(
              'connection to Isolate #${isolate.hashCode} failed: ${response.error}');
          completer.completeError(response.error!, response.error!.stackTrace);
        } else {
          channel._sendPort = response.result;
          Squadron.config('connected to Isolate #${isolate.hashCode}');
          completer.complete(channel);
        }
      }
    });
  }).catchError((ex, st) {
    completer.completeError(ex, st);
  });
  return completer.future;
}

/// Creates a [_VmChannel] from a [SendPort].
Channel? deserializeChannel(dynamic channelInfo) =>
    (channelInfo == null) ? null : (_VmChannel._().._sendPort = channelInfo);

/// Creates a [_VmWorkerChannel] from a [SendPort].
WorkerChannel? deserializeWorkerChannel(dynamic channelInfo) =>
    (channelInfo == null)
        ? null
        : (_VmWorkerChannel._().._sendPort = channelInfo);
