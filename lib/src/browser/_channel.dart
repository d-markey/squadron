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

class _BaseJsChannel {
  /// [web.MessagePort] to communicate with the [web.Worker] if the channel is owned by the worker owner. Otherwise,
  /// [web.MessagePort] to return values to the client.
  web.MessagePort? _sendPort;

  /// The ID of the worker attached to this [Channel].
  String get workerId => _workerId ?? '';
  String? _workerId;

  /// [Channel] serialization in JavaScript world returns the [web.MessagePort].
  dynamic serialize() => _sendPort;

  void _postRequest(WorkerRequest req, bool inspectRequest) {
    req.cancelToken?.ensureStarted();
    final message = req.serialize();
    try {
      final transfer = <Object>[];
      if (inspectRequest) {
        transfer.addAll(Transferables.get(message));
      } else {
        if (req.client != null) {
          transfer.add(req.client!.serialize());
        }
      }
      _sendPort!.postMessage(message, transfer);
    } catch (ex) {
      Squadron.severe('failed to post request $message: error $ex');
      rethrow;
    }
  }

  void _postResponse(WorkerResponse res, bool inspectResponse) {
    final message = res.serialize();
    try {
      if (inspectResponse) {
        final transfer = Transferables.get(message).toList();
        _sendPort!.postMessage(message, transfer);
      } else {
        _sendPort!.postMessage(message);
      }
    } catch (ex) {
      Squadron.severe('failed to post response $message: error $ex');
      rethrow;
    }
  }
}

/// [Channel] implementation for the JavaScript world.
class _JsChannel extends _BaseJsChannel implements Channel {
  _JsChannel._();

  /// [Channel] sharing in JavaScript world returns a [_JsForwardChannel].
  @override
  Channel share() => _JsForwardChannel._(_sendPort!);

  /// Sends a termination [WorkerRequest] to the [web.Worker] and clears the [web.MessagePort].
  @override
  FutureOr close() {
    if (_sendPort != null) {
      _postRequest(WorkerRequest.stop(), false);
      _sendPort = null;
    }
  }

  /// Creates a [web.MessageChannel] and a [WorkerRequest] and sends it to the [web.Worker]. This method expects a
  /// single value from the [web.Worker].
  @override
  Future<T> sendRequest<T>(int command, List args,
      {CancellationToken? token,
      bool inspectRequest = false,
      bool inspectResponse = false}) {
    final com = web.MessageChannel();
    final wrapper = ValueWrapper<T>(
      WorkerRequest(com.port2, command, args, token, inspectResponse),
      postMethod: _postRequest,
      messages: com.port1.onMessage.map((event) => event.data),
      token: token,
      inspectRequest: inspectRequest,
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
    final com = web.MessageChannel();
    final wrapper = StreamWrapper<T>(
      WorkerRequest(com.port2, command, args, token, inspectResponse),
      postMethod: _postRequest,
      messages: com.port1.onMessage.map((event) => event.data),
      onDone: () {
        com.port1.close();
        onDone();
      },
      token: token,
      inspectRequest: inspectRequest,
    );

    return wrapper.stream;
  }
}

/// [WorkerChannel] implementation for the JavaScript world.
class _JsWorkerChannel extends _BaseJsChannel implements WorkerChannel {
  _JsWorkerChannel._();

  /// Sends the [web.MessagePort] to communicate with the [web.Worker]. This method must be called by the
  /// [web.Worker] upon startup.
  @override
  void connect(Object channelInfo) {
    if (channelInfo is web.MessagePort) {
      reply(channelInfo, true);
    } else {
      throw WorkerException(
          'invalid channelInfo ${channelInfo.runtimeType}: MessagePort expected');
    }
  }

  /// Sends the [streamId] to the client. If the client cancels the streaming operation, it should inform the
  /// [Worker] that the stream has been cancelled on the client-side.
  @override
  void connectStream(int streamId) {
    reply(streamId, false);
  }

  /// Sends a [WorkerResponse] with the specified data to the worker client. This method must be called from the
  /// [web.Worker] only.
  @override
  void reply(dynamic data, bool inspectResponse) =>
      _postResponse(WorkerResponse(data), inspectResponse);

  @override
  void log(String message) => _postResponse(WorkerResponse.log(message), false);

  /// Checks if [stream] can be streamed back to the worker client. Returns `true` for browser platforms.
  @override
  bool canStream(Stream stream) => true;

  /// Sends a [WorkerResponse.closeStream] to the worker client. This method must be called from the [web.Worker]
  /// only.
  @override
  void closeStream() => _postResponse(WorkerResponse.closeStream, false);

  /// Sends the [WorkerResponse] to the worker client. This method must be called from the [web.Worker] only.
  @override
  void error(SquadronException error) {
    Squadron.debug(() => 'replying with error: $error');
    _postResponse(WorkerResponse.withError(error), false);
  }
}

/// [Channel] used to communicate between [web.Worker]s. Creates a [web.MessageChannel] to receive commands on
/// [web.MessageChannel.port2] and forwards them to the worker's [web.MessagePort] via [web.MessageChannel.port1].
class _JsForwardChannel extends _JsChannel {
  /// [remote] is the worker's [web.MessagePort]
  _JsForwardChannel._(web.MessagePort remote) : super._() {
    _remote = remote;
    _com.port1.onMessage.listen(_forward);
    _sendPort = _com.port2;
  }

  /// [web.MessagePort] to the worker.
  web.MessagePort? _remote;

  /// [web.MessageChannel] used for forwarding messages.
  final _com = web.MessageChannel();

  /// Forwards [web.MessageEvent.data] to the worker.
  void _forward(web.MessageEvent e) {
    final message = e.data;
    try {
      final transfer = Transferables.get(message).toList();
      _remote!.postMessage(message, transfer);
    } catch (ex) {
      Squadron.severe('failed to forward $message: error $ex');
      rethrow;
    }
  }

  /// Closes this [Channel], effectively stopping message forwarding.
  @override
  void close() {
    _remote = null;
    _com.port1.close();
  }
}

class Transferables {
  Transferables._();

  static final _instance = Transferables._();

  static Iterable<Object> get(Map args) => _instance._get(args, <Object>{});

  bool _isBaseType(dynamic value) =>
      (value == null || value is String || value is num || value is bool);

  bool _isListOfBaseType(dynamic value) =>
      (value is List<String> || value is List<num> || value is List<bool>);

  bool _isSafeForTransfer(dynamic value) {
    if (_isBaseType(value)) return true;
    if (_isListOfBaseType(value)) return true;
    if (value is List && value.every(_isSafeForTransfer)) return true;
    if (value is Map &&
        value.keys.every(_isBaseType) &&
        value.values.every(_isSafeForTransfer)) return true;
    return false;
  }

  /// Excludes base type values from [list].
  Iterable<Object> _getObjects(Iterable list, Set<Object> seen) sync* {
    for (var o in list.where((o) => !_isSafeForTransfer(o))) {
      if (!seen.contains(o)) {
        seen.add(o);
        yield o as Object;
      }
    }
  }

  /// Yields objects contained in [message]. Used to identify non-base type objects and provide them to
  /// [web.Worker.postMessage]. [web.Worker.postMessage] will clone these objects -- essentially
  /// [web.MessagePort]s. The code makes no effort to ensure these objects really are transferable.
  Iterable<Object> _get(Map message, Set<Object> seen) sync* {
    if (_isSafeForTransfer(message)) return;
    if (!message.keys.every(_isBaseType)) {
      throw newSquadronError('Keys must be strings, numbers or booleans.');
    }
    final toBeInspected = <Object>[];
    toBeInspected.addAll(_getObjects(message.values, seen));
    while (toBeInspected.isNotEmpty) {
      final arg = toBeInspected.removeLast();
      if (arg is Map) {
        toBeInspected.addAll(_get(arg, seen));
      } else if (arg is Iterable) {
        toBeInspected.addAll(_getObjects(arg, seen));
      } else {
        yield arg;
      }
    }
  }
}

/// Stub implementations

/// Starts a [web.Worker] using the [entryPoint] and sends a start [WorkerRequest] with [startArguments]. The future
/// completes after the [web.Worker]'s main program has provided the [web.MessagePort] via [_JsWorkerChannel.connect].
Future<Channel> openChannel(
    dynamic entryPoint, String workerId, List startArguments) {
  final completer = Completer<Channel>();
  final channel = _JsChannel._();
  final com = web.MessageChannel();
  final worker = web.Worker(entryPoint);

  final startRequest = WorkerRequest.start(com.port2, workerId, startArguments);

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
      final response = WorkerResponse.deserialize(event.data);
      if (response == null) return;

      if (!completer.isCompleted) {
        final error = response.error;
        if (error != null) {
          worker.terminate();
          Squadron.severe(
              'connection to Web Worker #$workerId failed: ${response.error}');
          completer.completeError(error, error.stackTrace);
        } else {
          channel._sendPort = response.result;
          channel._workerId = startRequest.id;
          Squadron.config('connected to Web Worker #$workerId');
          completer.complete(channel);
        }
      } else {
        Squadron.config('unexpected response: ${response.serialize()}');
      }
    },
  );

  final message = startRequest.serialize();
  try {
    final transfer = Transferables.get(message).toList();
    worker.postMessage(message, transfer);
  } catch (ex, st) {
    com.port1.close();
    com.port2.close();
    worker.terminate();
    Squadron.severe('failed to post connection request $message: error $ex');
    completer.completeError(SquadronException.from(ex, st), st);
  }
  return completer.future;
}

/// Creates a [_JsChannel] from a [web.MessagePort].
Channel? deserializeChannel(dynamic channelInfo) =>
    (channelInfo == null) ? null : (_JsChannel._().._sendPort = channelInfo);

/// Creates a [_JsWorkerChannel] from a [web.MessagePort].
WorkerChannel? deserializeWorkerChannel(dynamic channelInfo) =>
    (channelInfo == null)
        ? null
        : (_JsWorkerChannel._().._sendPort = channelInfo);
