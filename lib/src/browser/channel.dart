import 'dart:async';
import 'dart:html' as web;

import '../cancellation_token.dart';
import '../channel.dart' show Channel, WorkerChannel;
import '../squadron.dart';
import '../worker_exception.dart';
import '../worker_request.dart';
import '../worker_response.dart';

class _MessagePort {
  /// [web.MessagePort] to communicate with the [web.Worker] if the channel is owned by the worker owner.
  /// Otherwise, [web.MessagePort] to return values to the client.
  web.MessagePort? _sendPort;

  /// [Channel] serialization in JavaScript world returns the [web.MessagePort].
  dynamic serialize() => _sendPort;

  void _postRequest(WorkerRequest req) {
    final message = req.serialize();
    final transfer = _getTransferables(message).toList();
    try {
      _sendPort!.postMessage(message, transfer);
    } catch (ex) {
      Squadron.severe('Failed to post message: $ex');
      Squadron.severe('   message is $message with tranferables = $transfer');
      rethrow;
    }
  }
}

/// [Channel] implementation for the JavaScript world.
class JsChannel extends _MessagePort implements Channel {
  /// [Channel] sharing in JavaScript world returns a [_JsForwardChannel].
  @override
  Channel share() => _JsForwardChannel(_sendPort!);

  /// Sends a termination [WorkerRequest] to the [web.Worker] and clears the [web.MessagePort].
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
  void cancelToken(CancellationToken token) {
    if (token.cancelled) {
      _postRequest(WorkerRequest.cancel(token));
    }
  }

  /// Creates a [web.MessageChannel] and a [WorkerRequest] and sends it to the [web.Worker].
  /// This method expects a single value from the [web.Worker].
  @override
  Future<T> sendRequest<T>(int command, List args,
      {CancellationToken? token}) async {
    final com = web.MessageChannel();
    _postRequest(WorkerRequest(com.port2, command, args, token));
    final event = await com.port1.onMessage.first;
    final res = WorkerResponse.deserialize(event.data);
    return res.result as T;
  }

  /// Creates a [web.MessageChannel] and a [WorkerRequest] and sends it to the [web.Worker].
  /// This method expects a stream of values from the [web.Worker].
  /// The [web.Worker] must send a [WorkerResponse.endOfStream] to close the [Stream].
  @override
  Stream<T> sendStreamingRequest<T>(int command, List args,
      {CancellationToken? token}) async* {
    final com = web.MessageChannel();
    _postRequest(WorkerRequest(com.port2, command, args, token));
    await for (var event in com.port1.onMessage) {
      final res = WorkerResponse.deserialize(event.data);
      if (res.endOfStream) break;
      yield res.result as T;
    }
  }
}

/// [WorkerChannel] implementation for the JavaScript world.
class JsWorkerChannel extends _MessagePort implements WorkerChannel {
  /// Sends the [web.MessagePort] to communicate with the [web.Worker].
  /// This method must be called by the [web.Worker] upon startup.
  @override
  void connect(Object channelInfo) {
    try {
      if (channelInfo is web.MessagePort) {
        _sendPort!.postMessage(
            WorkerResponse(channelInfo).serialize(), [channelInfo]);
      } else {
        throw WorkerException(
            'Invalid channelInfo ${channelInfo.runtimeType}; expected MessagePort');
      }
    } catch (ex) {
      Squadron.severe('Failed to post connection response: $ex');
      rethrow;
    }
  }

  /// Sends the [WorkerResponse] to the worker client.
  /// This method must be called from the [web.Worker] only.
  @override
  void reply(WorkerResponse response) {
    if (response.hasError) {
      Squadron.fine('replying with error: ${response.error}');
    }
    final message = response.serialize();
    final transfer = _getTransferables(message).toList();
    try {
      _sendPort?.postMessage(message, transfer);
    } catch (ex) {
      Squadron.severe('Failed to post message: $ex');
      Squadron.severe('   message is $message with tranferables = $transfer');
      rethrow;
    }
  }
}

/// [Channel] used to communicate between [web.Worker]s.
/// Creates a [web.MessageChannel] to receive commands on [port2] and forwards them to the worker's [web.MessagePort] via [port1].
class _JsForwardChannel extends JsChannel {
  /// [remote] is the worker's [web.MessagePort]
  _JsForwardChannel(web.MessagePort remote) {
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
    final transfer = _getTransferables(message).toList();
    try {
      _remote!.postMessage(message, transfer);
    } catch (ex) {
      Squadron.severe('Failed to forward message: $ex');
      Squadron.severe('   message is $message with tranferables = $transfer');
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
    value != null && value is! num && value is! bool && value is! String;

/// Excludes base type values from [list].
Iterable<Object> _getObjects(Iterable list, Set<Object> seen) sync* {
  for (var o in list.where(_isObject)) {
    if (!seen.contains(o)) {
      seen.add(o);
      yield o as Object;
    }
  }
}

/// Yields objects contained in JSON object [args] (a Map, a List, or a base type).
/// Used to identify non-base type objects and provide them to [web.Worker.postMessage].
/// [web.Worker.postMessage] will clone these objects -- essentially [web.MessagePort]s.
/// The code makes no effort to ensure these objects really are transferable.
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

/// Starts a [web.Worker] using the [entryPoint] and sends a start [WorkerRequest] with [startArguments].
/// The future completes after the [web.Worker]'s main program has provided the [web.MessagePort] via [JsWorkerChannel.connect].
Future<Channel> openChannel(dynamic entryPoint, List startArguments) {
  final channel = JsChannel();
  final completer = Completer<Channel>();
  final com = web.MessageChannel();
  final message =
      WorkerRequest.start(com.port2, _getId(), startArguments).serialize();
  final transfer = _getTransferables(message).toList();
  final worker = web.Worker(entryPoint);
  Squadron.config('created Web Worker #${worker.hashCode}');
  worker.onError.listen((event) {
    com.port1.close();
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
    }
  });
  try {
    worker.postMessage(message, transfer);
  } catch (ex) {
    com.port1.close();
    worker.terminate();
    Squadron.severe('Failed to post connection request: $ex');
    Squadron.severe('   message is $message with tranferables = $transfer');
    rethrow;
  }
  com.port1.onMessage.listen((event) {
    com.port1.close();
    final response = WorkerResponse.deserialize(event.data);
    if (response.hasError) {
      worker.terminate();
      Squadron.severe(
          'connection to Web Worker #${worker.hashCode} failed: ${response.error}');
      completer.completeError(response.exception);
    } else {
      channel._sendPort = response.result;
      Squadron.config('connected to Web Worker #${worker.hashCode}');
      completer.complete(channel);
    }
  });
  return completer.future;
}

/// Creates a [JsChannel] from a [web.MessagePort].
Channel? deserializeChannel(dynamic channelInfo) =>
    (channelInfo == null) ? null : (JsChannel().._sendPort = channelInfo);

/// Creates a [JsWorkerChannel] from a [web.MessagePort].
WorkerChannel? deserializeWorkerChannel(dynamic channelInfo) =>
    (channelInfo == null) ? null : (JsWorkerChannel().._sendPort = channelInfo);
