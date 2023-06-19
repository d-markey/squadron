import 'dart:async';
import 'dart:isolate';

import '../xplat/_stream_wrapper.dart';
import '../cancellation_token.dart';
import '../channel.dart' show Channel, WorkerChannel;
import '../squadron.dart';
import '../squadron_exception.dart';
import '../worker_exception.dart';
import '../worker_request.dart';
import '../worker_response.dart';
import '../worker_service.dart';
import '../xplat/_value_wrapper.dart';

typedef EntryPoint = FutureOr<void> Function(List);
typedef PlatformWorker = Isolate;

typedef PlatformWorkerHook = FutureOr<void> Function(PlatformWorker);

class _BaseVmChannel {
  /// [SendPort] to communicate with the [Isolate] if the channel is owned by the worker owner. Otherwise, [SendPort]
  /// to return values to the client.
  SendPort? _sendPort;

  /// The ID of the worker attached to this [Channel].
  String get workerId => _workerId ?? '';
  String? _workerId;

  /// [Channel] serialization in Native world returns the [SendPort].
  dynamic serialize() => _sendPort;

  void _postRequest(WorkerRequest req, bool inspectRequest) {
    req.cancelToken?.ensureStarted();
    req.wrapRequest();
    try {
      _sendPort!.send(req);
    } catch (ex, st) {
      Squadron.severe('failed to post request $req: error $ex');
      throw SquadronException.from(ex, st);
    }
  }

  void _postResponse(WorkerResponse res, bool inspectResponse) {
    res.wrapResponse();
    try {
      _sendPort!.send(res);
    } catch (ex, st) {
      Squadron.severe('failed to post response $res: error $ex');
      throw SquadronException.from(ex, st);
    }
  }
}

/// [Channel] implementation for the Native world.
class _VmChannel extends _BaseVmChannel implements Channel {
  _VmChannel._();

  /// [Channel] sharing in Native world returns the same instance.
  @override
  Channel share() => this;

  /// Sends a termination [WorkerRequest] to the [Isolate] and clears the [SendPort].
  @override
  FutureOr close() {
    if (_sendPort != null) {
      _postRequest(WorkerRequestImpl.stop(), false);
      _sendPort = null;
    }
  }

  /// creates a [ReceivePort] and a [WorkerRequest] and sends it to the [Isolate]. This method expects a single
  /// value from the [Isolate]
  @override
  Future<T> sendRequest<T>(int command, List args,
      {CancellationToken? token,
      bool inspectRequest = false,
      bool inspectResponse = false}) {
    final receiver = ReceivePort();
    final wrapper = ValueWrapper<T>(
      WorkerRequestImpl.userCommand(
          receiver.sendPort, command, args, token, inspectResponse),
      postMethod: _postRequest,
      messages: receiver,
      token: token,
      inspectRequest: inspectRequest,
    );
    return wrapper.compute().whenComplete(() => receiver.close());
  }

  /// Creates a [ReceivePort] and a [WorkerRequest] and sends it to the [Isolate]. This method expects a stream of
  /// values from the [Isolate]. The [Isolate] must send a [WorkerResponse.endOfStream] to close the [Stream].
  @override
  Stream<T> sendStreamingRequest<T>(int command, List args,
      {SquadronCallback onDone = Channel.noop,
      CancellationToken? token,
      bool inspectRequest = false,
      bool inspectResponse = false}) {
    final receiver = ReceivePort();
    final wrapper = StreamWrapper<T>(
      WorkerRequestImpl.userCommand(
          receiver.sendPort, command, args, token, inspectResponse),
      postMethod: _postRequest,
      messages: receiver,
      onDone: () {
        receiver.close();
        onDone();
      },
      token: token,
      inspectRequest: inspectRequest,
    );

    return wrapper.stream;
  }
}

/// [WorkerChannel] implementation for the native world.
class _VmWorkerChannel extends _BaseVmChannel implements WorkerChannel {
  _VmWorkerChannel._();

  /// Sends the [SendPort] to communicate with the [Isolate]. This method must be called by the [Isolate] upon
  /// startup.
  @override
  void connect(Object channelInfo) {
    if (channelInfo is ReceivePort) {
      reply(channelInfo.sendPort, true);
    } else {
      throw WorkerException(
          'invalid channelInfo ${channelInfo.runtimeType}: ReceivePort expected');
    }
  }

  /// Sends the [streamId] to the client. If the client cancels the streaming operation, it should inform the
  /// [Worker] that the stream has been cancelled on the client-side.
  @override
  void connectStream(int streamId) {
    reply(streamId, false);
  }

  /// Sends a [WorkerResponse] with the specified data to the worker client. This method must be called from the
  /// [Isolate] only.
  @override
  void reply(dynamic data, bool inspectResponse) =>
      _postResponse(WorkerResponseImpl.withResult(data), inspectResponse);

  @override
  void log(String message) =>
      _postResponse(WorkerResponseImpl.log(message), false);

  /// Checks if [stream] can be streamed back to the worker client. Returns `true` unless [stream] is a
  /// [ReceivePort].
  @override
  bool canStream(Stream stream) => stream is! ReceivePort;

  /// Sends a [WorkerResponse.closeStream] to the worker client. This method must be called from the [Isolate] only.
  @override
  void closeStream() => _postResponse(WorkerResponseImpl.closeStream(), false);

  /// Sends the [WorkerException] to the worker client. This method must be called from the [Isolate] only.
  @override
  void error(SquadronException error) {
    Squadron.debug('replying with error: $error');
    _postResponse(WorkerResponseImpl.withError(error), false);
  }
}

// Stub implementations.

/// Starts an [Isolate] using the [entryPoint] and sends a start [WorkerRequest] with [startArguments]. The future
/// completes after the [Isolate]'s main program has provided the [SendPort] via [_VmWorkerChannel.connect].
Future<Channel> openChannel(
    EntryPoint entryPoint, String workerId, List startArguments,
    [PlatformWorkerHook? hook]) async {
  final completer = Completer<Channel>();
  final channel = _VmChannel._();
  final receiver = ReceivePort();

  final startRequest =
      WorkerRequestImpl.start(receiver.sendPort, workerId, startArguments);

  late final Isolate isolate;
  final exitPort = ReceivePort();
  final errorPort = ReceivePort();

  exitPort.listen((message) {
    Squadron.config('Isolate #$workerId terminated.');
    channel.close();
    receiver.close();
    exitPort.close();
    errorPort.close();
  });

  errorPort.listen((message) {
    final error = SquadronException.fromString(message[0]) ??
        WorkerException(message[0],
            stackTrace: SquadronException.loadStackTrace(message[1]));
    Squadron.warning(
        'Unhandled error from Isolate #$workerId: ${error.message}.');
    if (!completer.isCompleted) {
      completer.completeError(error, error.stackTrace);
    }
  });

  receiver.listen((message) {
    final response = message as List;
    if (!response.unwrapResponse()) {
      return;
    }

    if (!completer.isCompleted) {
      final error = response.error;
      if (error != null) {
        isolate.kill(priority: Isolate.immediate);
        Squadron.severe(
            'connection to Isolate #$workerId failed: ${response.error}');
        completer.completeError(error, error.stackTrace);
      } else {
        channel._sendPort = response.result;
        channel._workerId = workerId;
        Squadron.config('connected to Isolate #$workerId');
        completer.complete(channel);
      }
    } else {
      Squadron.config('unexpected response: $response');
    }
  });

  startRequest.wrapRequest();
  isolate = await Isolate.spawn(
    entryPoint,
    startRequest,
    errorsAreFatal: false,
    onExit: exitPort.sendPort,
    onError: errorPort.sendPort,
  );

  try {
    hook?.call(isolate);
  } catch (ex) {
    Squadron.warning(
        'An exception occurred in PlatforWorkerHook for $entryPoint: $ex');
  }

  Squadron.config('created Isolate #$workerId');
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
