import 'dart:async';
import 'dart:isolate';

import '../../channel.dart' show Channel;
import '../../exceptions/squadron_error.dart';
import '../../exceptions/squadron_exception.dart';
import '../../exceptions/worker_exception.dart';
import '../../squadron.dart';
import '../../tokens/cancellation_token.dart';
import '../../worker/worker_channel.dart';
import '../../worker/worker_request.dart';
import '../../worker/worker_response.dart';
import '../../worker/worker_service.dart';
import '../xplat/_stream_wrapper.dart';
import '../xplat/_value_wrapper.dart';

typedef EntryPoint = FutureOr<void> Function(List);
typedef PlatformWorker = Isolate;

typedef PlatformWorkerHook = FutureOr<void> Function(PlatformWorker);

class _BaseVmChannel {
  _BaseVmChannel._(this.workerId, this._sendPort);

  /// [SendPort] to communicate with the [Isolate] if the channel is owned by the worker owner. Otherwise, [SendPort]
  /// to return values to the client.
  final SendPort _sendPort;

  /// The ID of the worker attached to this [Channel].
  final String workerId;

  /// [Channel] serialization in Native world returns the [SendPort].
  dynamic serialize() => _sendPort;

  void _postRequest(WorkerRequest req) {
    req.cancelToken?.ensureStarted();
    req.wrapRequest();
    try {
      _sendPort.send(req);
    } catch (ex, st) {
      Squadron.severe('failed to post request $req: error $ex');
      throw SquadronException.from(ex, st);
    }
  }

  void _inspectAndPostRequest(WorkerRequest req) => _postRequest(req);

  void _postResponse(WorkerResponse res) {
    res.wrapResponse();
    try {
      _sendPort.send(res);
    } catch (ex, st) {
      Squadron.severe('failed to post response $res: error $ex');
      throw SquadronException.from(ex, st);
    }
  }
}

/// [Channel] implementation for the Native world.
class _VmChannel extends _BaseVmChannel implements Channel {
  _VmChannel._(String workerId, SendPort sendPort)
      : super._(workerId, sendPort);

  bool _closed = false;

  /// [Channel] sharing in Native world returns the same instance.
  @override
  Channel share() => this;

  /// Sends a termination [WorkerRequest] to the [Isolate] and clears the [SendPort].
  @override
  FutureOr close() {
    if (!_closed) {
      _postRequest(WorkerRequestImpl.stop());
      _closed = true;
    }
  }

  /// creates a [ReceivePort] and a [WorkerRequest] and sends it to the [Isolate]. This method expects a single
  /// value from the [Isolate]
  @override
  Future<T> sendRequest<T>(int command, List args,
      {CancellationToken? token,
      bool inspectRequest = false,
      bool inspectResponse = false}) {
    if (_closed) {
      throw SquadronErrorExt.create('Channel is closed', StackTrace.current);
    }
    final receiver = ReceivePort();
    final wrapper = ValueWrapper<T>(
      WorkerRequestImpl.userCommand(
          receiver.sendPort, command, args, token, inspectResponse),
      postMethod: inspectRequest ? _inspectAndPostRequest : _postRequest,
      messages: receiver,
      token: token,
    );
    return wrapper.compute().whenComplete(receiver.close);
  }

  /// Creates a [ReceivePort] and a [WorkerRequest] and sends it to the [Isolate]. This method expects a stream of
  /// values from the [Isolate]. The [Isolate] must send a [WorkerResponse.endOfStream] to close the [Stream].
  @override
  Stream<T> sendStreamingRequest<T>(int command, List args,
      {SquadronCallback onDone = Channel.noop,
      CancellationToken? token,
      bool inspectRequest = false,
      bool inspectResponse = false}) {
    if (_closed) {
      throw SquadronErrorExt.create('Channel is closed', StackTrace.current);
    }
    final receiver = ReceivePort();
    final wrapper = StreamWrapper<T>(
      WorkerRequestImpl.userCommand(
          receiver.sendPort, command, args, token, inspectResponse),
      postMethod: inspectRequest ? _inspectAndPostRequest : _postRequest,
      messages: receiver,
      onDone: () {
        receiver.close();
        onDone();
      },
      token: token,
    );

    return wrapper.stream;
  }
}

/// [WorkerChannel] implementation for the native world.
class _VmWorkerChannel extends _BaseVmChannel implements WorkerChannel {
  _VmWorkerChannel._(String workerId, SendPort sendPort)
      : super._(workerId, sendPort);

  /// Sends the [SendPort] to communicate with the [Isolate]. This method must be called by the [Isolate] upon
  /// startup.
  @override
  void connect(Object channelInfo) {
    if (channelInfo is ReceivePort) {
      inspectAndReply(channelInfo.sendPort);
    } else {
      throw WorkerException(
          'invalid channelInfo ${channelInfo.runtimeType}: ReceivePort expected');
    }
  }

  /// Sends a [WorkerResponse] with the specified data to the worker client. This method must be called from the
  /// [Isolate] only.
  @override
  void reply(dynamic data) =>
      _postResponse(WorkerResponseImpl.withResult(data));

  /// Sends a [WorkerResponse] with the specified data to the worker client. This method must be called from the
  /// [Isolate] only. Same as [reply] on VM platforms.
  @override
  void inspectAndReply(dynamic data) => reply(data);

  @override
  void log(String message) => _postResponse(WorkerResponseImpl.log(message));

  /// Checks if [stream] can be streamed back to the worker client. Returns `true` unless [stream] is a
  /// [ReceivePort].
  @override
  bool canStream(Stream stream) => stream is! ReceivePort;

  /// Sends a [WorkerResponse.closeStream] to the worker client. This method must be called from the [Isolate] only.
  @override
  void closeStream() => _postResponse(WorkerResponseImpl.closeStream());

  /// Sends the [WorkerException] to the worker client. This method must be called from the [Isolate] only.
  @override
  void error(SquadronException error) {
    Squadron.debug('replying with error: $error');
    _postResponse(WorkerResponseImpl.withError(error));
  }
}

// Stub implementations.

/// Starts an [Isolate] using the [entryPoint] and sends a start [WorkerRequest] with [startArguments]. The future
/// completes after the [Isolate]'s main program has provided the [SendPort] via [_VmWorkerChannel.connect].
Future<Channel> openChannel(
    EntryPoint entryPoint, String workerId, List startArguments,
    [PlatformWorkerHook? hook]) async {
  final completer = Completer<Channel>();
  final receiver = ReceivePort();

  final startRequest =
      WorkerRequestImpl.start(receiver.sendPort, workerId, startArguments);

  late final Isolate isolate;
  final exitPort = ReceivePort();
  final errorPort = ReceivePort();

  exitPort.listen((message) {
    Squadron.config('Isolate #$workerId terminated.');
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
        Squadron.config('connected to Isolate #$workerId');
        completer.complete(_VmChannel._(workerId, response.result));
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
    (channelInfo == null) ? null : _VmChannel._('<deserialized>', channelInfo);

/// Creates a [_VmWorkerChannel] from a [SendPort].
WorkerChannel? deserializeWorkerChannel(dynamic channelInfo) =>
    (channelInfo == null)
        ? null
        : _VmWorkerChannel._('<deserialized>', channelInfo);
