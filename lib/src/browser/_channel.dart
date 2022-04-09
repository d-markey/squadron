import 'dart:async';
import 'dart:html' as web;

import '../cancellation_token.dart';
import '../channel.dart' show Channel, WorkerChannel;
import '../squadron.dart';
import '../squadron_exception.dart';
import '../worker_exception.dart';
import '../worker_request.dart';
import '../worker_response.dart';

class _MessagePort {
  /// [web.MessagePort] to communicate with the [web.Worker] if the channel is owned by the worker owner. Otherwise,
  /// [web.MessagePort] to return values to the client.
  web.MessagePort? _sendPort;

  /// [Channel] serialization in JavaScript world returns the [web.MessagePort].
  dynamic serialize() => _sendPort;

  void _postRequest(WorkerRequest req) {
    final message = req.serialize();
    try {
      final transfer = _getTransferables(message).toList();
      _sendPort!.postMessage(message, transfer);
    } catch (ex) {
      Squadron.severe('failed to post request $message: error $ex');
      rethrow;
    }
  }

  void _postResponse(WorkerResponse res) {
    final message = res.serialize();
    try {
      final transfer = _getTransferables(message).toList();
      _sendPort!.postMessage(message, transfer);
    } catch (ex) {
      Squadron.severe('failed to post response $message: error $ex');
      rethrow;
    }
  }
}

/// [Channel] implementation for the JavaScript world.
class _JsChannel extends _MessagePort implements Channel {
  _JsChannel._();

  /// [Channel] sharing in JavaScript world returns a [_JsForwardChannel].
  @override
  Channel share() => _JsForwardChannel._(_sendPort!);

  /// Sends a termination [WorkerRequest] to the [web.Worker] and clears the [web.MessagePort].
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

  /// Creates a [web.MessageChannel] and a [WorkerRequest] and sends it to the [web.Worker]. This method expects a
  /// single value from the [web.Worker].
  @override
  Future<T> sendRequest<T>(int command, List args,
      {CancellationToken? token}) async {
    final com = web.MessageChannel();
    try {
      _postRequest(WorkerRequest(com.port2, command, args, token));
      final event = await com.port1.onMessage.first;
      final res = WorkerResponse.deserialize(event.data);
      return res.result as T;
    } finally {
      com.port2.close();
      com.port1.close();
    }
  }

  /// Creates a [web.MessageChannel] and a [WorkerRequest] and sends it to the [web.Worker]. This method expects a
  /// stream of values from the [web.Worker]. The [web.Worker] must send a [WorkerResponse.endOfStream] to close
  /// the [Stream].
  @override
  Stream<T> sendStreamingRequest<T>(int command, List args,
      {CancellationToken? token}) {
    late final StreamController<T> controller;
    final com = web.MessageChannel();
    bool cancelled = false;
    bool paused = false;

    void process(web.MessageEvent event) {
      if (cancelled) return;
      final res = WorkerResponse.deserialize(event.data);
      if (res.endOfStream) {
        Squadron.info('[process] close');
        controller.close();
        cancelled = true;
        // com.port1.close();
      } else if (res.hasError) {
        Squadron.info('[process] error');
        controller.addError(res.error!, res.error!.stackTrace);
        controller.close();
        cancelled = true;
        // com.port1.close();
      } else {
        controller.add(res.result);
      }
    }

    final buffer = <web.MessageEvent>[];

    void onListen() {
      Squadron.info('[onListen] start streaming');
      com.port1.onMessage.listen((event) {
        if (cancelled) return;
        if (paused) {
          Squadron.info('[onListen] paused');
          buffer.add(event);
        } else {
          process(event);
        }
      });
      _postRequest(WorkerRequest(com.port2, command, args, token));
    }

    void onCancel() {
      Squadron.info('[onCancel] cancelling');
      cancelled = true;
      com.port1.close();
      controller.close();
    }

    void onPause() {
      Squadron.info('[onPause] pausing');
      paused = true;
    }

    void onResume() {
      Squadron.info('[onResume] resuming');
      if (buffer.isNotEmpty) {
        Squadron.info('[onResume] processing buffered events');
        for (var e in buffer) {
          process(e);
        }
        buffer.clear();
      }
      paused = false;
    }

    controller = StreamController(
      onListen: onListen,
      onPause: onPause,
      onResume: onResume,
      onCancel: onCancel,
    );

    return controller.stream;
  }
}

/// [WorkerChannel] implementation for the JavaScript world.
class _JsWorkerChannel extends _MessagePort implements WorkerChannel {
  _JsWorkerChannel._();

  /// Sends the [web.MessagePort] to communicate with the [web.Worker]. This method must be called by the
  /// [web.Worker] upon startup.
  @override
  void connect(Object channelInfo) {
    if (channelInfo is web.MessagePort) {
      reply(channelInfo);
    } else {
      throw WorkerException(
          'invalid channelInfo ${channelInfo.runtimeType}: MessagePort expected');
    }
  }

  /// Sends a [WorkerResponse] with the specified data to the worker client. This method must be called from the
  /// [web.Worker] only.
  @override
  void reply(dynamic data) => _postResponse(WorkerResponse(data));

  /// Checks if [stream] can be streamed back to the worker client. Returns `true` for browser platforms.
  @override
  bool canStream(Stream stream) => true;

  /// Sends a [WorkerResponse.closeStream] to the worker client. This method must be called from the [web.Worker]
  /// only.
  @override
  void closeStream() => _postResponse(WorkerResponse.closeStream);

  /// Sends the [WorkerResponse] to the worker client. This method must be called from the [web.Worker] only.
  @override
  void error(SquadronException error) {
    Squadron.finer(() => 'replying with error: $error');
    _postResponse(WorkerResponse.withError(error));
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
      final transfer = _getTransferables(message).toList();
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

/// Checks if [value] is a base type value or an object.
bool _isObject(dynamic value) =>
    value != null &&
    value is! num &&
    value is! bool &&
    value is! String &&
    value is! List<num> &&
    value is! List<bool> &&
    value is! List<String>;

/// Excludes base type values from [list].
Iterable<Object> _getObjects(Iterable list, Set<Object> seen) sync* {
  for (var o in list.where(_isObject)) {
    if (!seen.contains(o)) {
      seen.add(o);
      yield o as Object;
    }
  }
}

/// Yields objects contained in JSON object [args] (a Map, a List, or a base type). Used to identify non-base type
/// objects and provide them to [web.Worker.postMessage]. [web.Worker.postMessage] will clone these objects
/// -- essentially [web.MessagePort]s. The code makes no effort to ensure these objects really are transferable.
Iterable<Object> _getTransferables(dynamic args) sync* {
  if (_isObject(args)) {
    if (args is Map) args = args.values;
    if (args is! Iterable) {
      yield args as Object;
    } else {
      final seen = <Object>{};
      final toBeInspected = <Object>[];
      toBeInspected.addAll(_getObjects(args, seen));
      var i = 0;
      while (i < toBeInspected.length) {
        final arg = toBeInspected[i++];
        if (arg is Map) {
          toBeInspected.addAll(_getObjects(arg.values, seen));
        } else if (arg is Iterable) {
          toBeInspected.addAll(_getObjects(arg, seen));
        } else {
          yield arg;
        }
      }
    }
  }
}

/// Stub implementations

int _counter = 0;
String _getId() {
  _counter++;
  return '${Squadron.id}.$_counter';
}

/// Starts a [web.Worker] using the [entryPoint] and sends a start [WorkerRequest] with [startArguments]. The future
/// completes after the [web.Worker]'s main program has provided the [web.MessagePort] via [_JsWorkerChannel.connect].
Future<Channel> openChannel(dynamic entryPoint, List startArguments) {
  final completer = Completer<Channel>();
  final channel = _JsChannel._();
  final com = web.MessageChannel();
  final worker = web.Worker(entryPoint);
  Squadron.config('created Web Worker #${worker.hashCode}');
  worker.onError.listen((event) {
    String msg;
    if (event is web.ErrorEvent) {
      final error = event;
      msg =
          '$entryPoint => ${error.message} [${error.filename}(${error.lineno})]';
    } else {
      msg = '$entryPoint: ${event.type} / $event';
    }
    Squadron.severe('error in Web Worker #${worker.hashCode}: $msg');
    if (!completer.isCompleted) {
      completer.completeError(
          WorkerException('error in Web Worker #${worker.hashCode}: $msg'));
      worker.terminate();
    }
  });
  final message =
      WorkerRequest.start(com.port2, _getId(), startArguments).serialize();
  try {
    final transfer = _getTransferables(message).toList();
    worker.postMessage(message, transfer);
  } catch (ex) {
    com.port1.close();
    worker.terminate();
    Squadron.severe('failed to post connection request $message: error $ex');
    rethrow;
  }
  com.port1.onMessage.listen((event) {
    com.port1.close();
    final response = WorkerResponse.deserialize(event.data);
    SquadronException? error = response.error;
    if (error == null) {
      try {
        channel._sendPort = response.result;
        Squadron.config('connected to Web Worker #${worker.hashCode}');
        completer.complete(channel);
      } catch (ex, st) {
        error = SquadronException.from(error: ex, stackTrace: st);
      }
    }
    if (error != null) {
      worker.terminate();
      Squadron.severe(
          'connection to Web Worker #${worker.hashCode} failed: ${response.error}');
      completer.completeError(error, error.stackTrace);
    }
  });
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
