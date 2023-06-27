import 'dart:async';
import 'dart:html' as web;

import '../squadron_error.dart';
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
import '_transferables.dart';

typedef EntryPoint = String;
typedef PlatformWorker = web.Worker;

typedef PlatformWorkerHook = FutureOr<void> Function(PlatformWorker);

class _BaseJsChannel {
  _BaseJsChannel._(this.workerId, this._sendPort);

  /// [web.MessagePort] to communicate with the [web.Worker] if the channel is owned by the worker owner. Otherwise,
  /// [web.MessagePort] to return values to the client.
  final web.MessagePort _sendPort;

  /// The ID of the worker attached to this [Channel].
  final String workerId;

  /// [Channel] serialization in JavaScript world returns the [web.MessagePort].
  dynamic serialize() => _sendPort;

  void _postRequest(WorkerRequest req) {
    req.cancelToken?.ensureStarted();
    req.wrapRequest();
    try {
      _sendPort.postMessage(
          req, (req.channelInfo == null) ? null : [req.channelInfo]);
    } catch (ex, st) {
      Squadron.severe('failed to post request $req: error $ex');
      throw SquadronException.from(ex, st);
    }
  }

  void _inspectAndPostRequest(WorkerRequest req) {
    req.cancelToken?.ensureStarted();
    req.wrapRequest();
    try {
      _sendPort.postMessage(req, Transferables.get(req).toList());
    } catch (ex, st) {
      Squadron.severe('failed to post request $req: error $ex');
      throw SquadronException.from(ex, st);
    }
  }

  void _postResponse(WorkerResponse res) {
    res.wrapResponse();
    try {
      _sendPort.postMessage(res);
    } catch (ex, st) {
      Squadron.severe('failed to post response $res: error $ex');
      throw SquadronException.from(ex, st);
    }
  }

  void _inspectAndPostResponse(WorkerResponse res) {
    res.wrapResponse();
    try {
      _sendPort.postMessage(res, Transferables.get(res).toList());
    } catch (ex, st) {
      Squadron.severe('failed to post response $res: error $ex');
      throw SquadronException.from(ex, st);
    }
  }
}

/// [Channel] implementation for the JavaScript world.
class _JsChannel extends _BaseJsChannel implements Channel {
  _JsChannel._(String workerId, web.MessagePort sendPort)
      : super._(workerId, sendPort);

  bool _closed = false;

  /// [Channel] sharing in JavaScript world returns a [_JsForwardChannel].
  @override
  Channel share() => _JsForwardChannel._(_sendPort, web.MessageChannel());

  /// Sends a termination [WorkerRequest] to the [web.Worker] and clears the [web.MessagePort].
  @override
  FutureOr close() {
    if (!_closed) {
      _postRequest(WorkerRequestImpl.stop());
      _closed = true;
    }
  }

  /// Creates a [web.MessageChannel] and a [WorkerRequest] and sends it to the [web.Worker]. This method expects a
  /// single value from the [web.Worker].
  @override
  Future<T> sendRequest<T>(int command, List args,
      {CancellationToken? token,
      bool inspectRequest = false,
      bool inspectResponse = false}) {
    if (_closed) {
      throw newSquadronError('Channel is closed', StackTrace.current);
    }
    final com = web.MessageChannel();
    final wrapper = ValueWrapper<T>(
      WorkerRequestImpl.userCommand(
          com.port2, command, args, token, inspectResponse),
      postMethod: inspectRequest ? _inspectAndPostRequest : _postRequest,
      messages: com.port1.onMessage.map((event) => event.data),
      token: token,
    );
    return wrapper.compute().whenComplete(() {
      com.port1.close();
      com.port2.close();
    });
  }

  /// Creates a [web.MessageChannel] and a [WorkerRequest] and sends it to the [web.Worker]. This method expects a
  /// stream of values from the [web.Worker]. The [web.Worker] must send a [WorkerResponse.endOfStream] to close
  /// the [Stream].
  @override
  Stream<T> sendStreamingRequest<T>(int command, List args,
      {SquadronCallback onDone = Channel.noop,
      CancellationToken? token,
      bool inspectRequest = false,
      bool inspectResponse = false}) {
    if (_closed) {
      throw newSquadronError('Channel is closed', StackTrace.current);
    }
    final com = web.MessageChannel();
    final wrapper = StreamWrapper<T>(
      WorkerRequestImpl.userCommand(
          com.port2, command, args, token, inspectResponse),
      postMethod: inspectRequest ? _inspectAndPostRequest : _postRequest,
      messages: com.port1.onMessage.map((event) => event.data),
      onDone: () {
        com.port1.close();
        onDone();
      },
      token: token,
    );

    return wrapper.stream;
  }
}

/// [WorkerChannel] implementation for the JavaScript world.
class _JsWorkerChannel extends _BaseJsChannel implements WorkerChannel {
  _JsWorkerChannel._(String workerId, web.MessagePort sendPort)
      : super._(workerId, sendPort);

  /// Sends the [web.MessagePort] to communicate with the [web.Worker]. This method must be called by the
  /// [web.Worker] upon startup.
  @override
  void connect(Object channelInfo) {
    if (channelInfo is web.MessagePort) {
      inspectAndReply(channelInfo);
    } else {
      throw WorkerException(
          'invalid channelInfo ${channelInfo.runtimeType}: MessagePort expected');
    }
  }

  /// Sends a [WorkerResponse] with the specified data to the worker client. This method must be called from the
  /// [web.Worker] only. On Web patforms, this version does not check arguments for transferable objects.
  @override
  void reply(dynamic data) =>
      _postResponse(WorkerResponseImpl.withResult(data));

  /// Sends a [WorkerResponse] with the specified data to the worker client. This method must be called from the
  /// [web.Worker] only. On Web patforms, this version checks arguments for transferable objects.
  @override
  void inspectAndReply(dynamic data) =>
      _inspectAndPostResponse(WorkerResponseImpl.withResult(data));

  @override
  void log(String message) => _postResponse(WorkerResponseImpl.log(message));

  /// Checks if [stream] can be streamed back to the worker client. Returns `true` for browser platforms.
  @override
  bool canStream(Stream stream) => true;

  /// Sends a [WorkerResponse.closeStream] to the worker client. This method must be called from the [web.Worker]
  /// only.
  @override
  void closeStream() => _postResponse(WorkerResponseImpl.closeStream());

  /// Sends the [WorkerResponse] to the worker client. This method must be called from the [web.Worker] only.
  @override
  void error(SquadronException error) {
    Squadron.debug(() => 'replying with error: $error');
    _postResponse(WorkerResponseImpl.withError(error));
  }
}

/// [Channel] used to communicate between [web.Worker]s. Creates a [web.MessageChannel] to receive commands on
/// [web.MessageChannel.port2] and forwards them to the worker's [web.MessagePort] via [web.MessageChannel.port1].
class _JsForwardChannel extends _JsChannel {
  /// [_remote] is the worker's [web.MessagePort], [_com] is the intermediate message channel
  _JsForwardChannel._(this._remote, this._com)
      : super._('<forward>', _com.port2) {
    _com.port1.onMessage.listen(_forward);
  }

  /// [web.MessagePort] to the worker.
  final web.MessagePort _remote;

  /// [web.MessageChannel] used for forwarding messages.
  final web.MessageChannel _com;

  /// Forwards [web.MessageEvent.data] to the worker.
  void _forward(web.MessageEvent e) {
    if (_closed) {
      throw newSquadronError('Channel is closed', StackTrace.current);
    }
    final message = e.data;
    try {
      _remote.postMessage(message, Transferables.get(message).toList());
    } catch (ex, st) {
      Squadron.severe('failed to forward $message: error $ex');
      throw SquadronException.from(ex, st);
    }
  }

  /// Closes this [Channel], effectively stopping message forwarding.
  @override
  void close() {
    if (!_closed) {
      _com.port1.close();
      _closed = true;
    }
  }
}

/// Stub implementations

/// Starts a [web.Worker] using the [entryPoint] and sends a start [WorkerRequest] with [startArguments]. The future
/// completes after the [web.Worker]'s main program has provided the [web.MessagePort] via [_JsWorkerChannel.connect].
Future<Channel> openChannel(
    EntryPoint entryPoint, String workerId, List startArguments,
    [PlatformWorkerHook? hook]) {
  final completer = Completer<Channel>();
  final com = web.MessageChannel();
  final worker = web.Worker(entryPoint);

  try {
    hook?.call(worker);
  } catch (ex) {
    Squadron.warning(
        'An exception occurred in PlatforWorkerHook for $entryPoint: $ex');
  }

  final startRequest =
      WorkerRequestImpl.start(com.port2, workerId, startArguments);

  Squadron.config('created Web Worker #$workerId');

  worker.onError.listen(
    (event) {
      String msg;
      if (event is web.ErrorEvent) {
        final error = event;
        msg =
            '$entryPoint => ${error.message} [${error.filename}(${error.lineno})]';
      } else {
        msg = '$entryPoint: ${event.type} / $event';
      }
      final error = WorkerException(msg);
      Squadron.warning(
          'Unhandled error from Web worker #$workerId: ${error.message}.');
      if (!completer.isCompleted) {
        completer.completeError(error, error.stackTrace);
      }
    },
  );

  com.port1.onMessage.listen(
    (event) {
      final response = event.data as List;
      if (!response.unwrapResponse()) {
        return;
      }

      if (!completer.isCompleted) {
        final error = response.error;
        if (error != null) {
          worker.terminate();
          Squadron.severe(
              'connection to Web Worker #$workerId failed: ${response.error}');
          completer.completeError(error, error.stackTrace);
        } else {
          Squadron.config('connected to Web Worker #$workerId');
          completer.complete(_JsChannel._(workerId, response.result));
        }
      } else {
        Squadron.config('unexpected response: $response');
      }
    },
  );

  startRequest.wrapRequest();
  try {
    final transfer = Transferables.get(startRequest).toList();
    worker.postMessage(startRequest, transfer);
  } catch (ex, st) {
    com.port1.close();
    com.port2.close();
    worker.terminate();
    Squadron.severe(
        'failed to post connection request $startRequest: error $ex');
    completer.completeError(SquadronException.from(ex, st), st);
  }
  return completer.future;
}

/// Creates a [_JsChannel] from a [web.MessagePort].
Channel? deserializeChannel(dynamic channelInfo) =>
    (channelInfo == null) ? null : _JsChannel._('<deserialized>', channelInfo);

/// Creates a [_JsWorkerChannel] from a [web.MessagePort].
WorkerChannel? deserializeWorkerChannel(dynamic channelInfo) =>
    (channelInfo == null)
        ? null
        : _JsWorkerChannel._('<deserialized>', channelInfo);
