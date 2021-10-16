import 'dart:async';
import 'dart:html' as web;

import '../channel.dart';
import '../worker_exception.dart';
import '../worker_request.dart';
import '../worker_response.dart';

/// [Channel] implementation for the JavaScript world
class JsChannel implements Channel {
  /// [web.MessagePort] to communicate with the [web.Worker] if the channel is owned by the worker owner
  /// otherwise, [web.MessagePort] to return values to the client
  web.MessagePort? _sendPort;

  /// [Channel] serialization in JavaScript world returns the [web.MessagePort]
  @override
  dynamic serialize() {
    return _sendPort;
  }

  /// [Channel] sharing in JavaScript world returns a [_JsForwardChannel]
  @override
  Channel share() {
    return _JsForwardChannel(_sendPort!);
  }

  /// sends the [web.MessagePort] to communicate with the [web.Worker]
  /// this method must be called by the [web.Worker] upon startup
  @override
  void connect(Object channelInfo) {
    if (channelInfo is web.MessagePort) {
      _sendPort!.postMessage(channelInfo, [channelInfo]);
    } else {
      throw WorkerException(
          'Invalid channelInfo $channelInfo; expected ReceivePort or SendPort');
    }
  }

  /// wrapper of [web.Worker.postMessage] to send a [WorkerRequest]
  void _postRequest(WorkerRequest req) {
    final message = req.serialize();
    final transfer = _getTransferables(message).toList();
    _sendPort!.postMessage(message, transfer);
  }

  /// sends a termination [WorkerRequest] to the [web.Worker] and clears the [web.MessagePort]
  @override
  FutureOr close() {
    if (_sendPort != null) {
      _postRequest(WorkerRequest.terminate());
      _sendPort = null;
    }
  }

  /// creates a [web.MessageChannel] and a [WorkerRequest] and sends it to the [web.Worker]
  /// this method expects a single value from the [web.Worker]
  @override
  Future<T> sendRequest<T>(int command, List args) {
    final completer = Completer<T>();
    final com = web.MessageChannel();
    _postRequest(WorkerRequest(com.port2, command, args));
    com.port1.onMessage.listen((event) {
      final res = WorkerResponse.deserialize(event.data);
      com.port1.close();
      if (res.hasError) {
        completer.completeError(res.exception!);
      } else {
        completer.complete(res.result);
      }
    });
    return completer.future;
  }

  /// creates a [web.MessageChannel] and a [WorkerRequest] and sends it to the [web.Worker]
  /// this method expects a stream of values from the [web.Worker]
  /// the [web.Worker] must send a [WorkerResponse.endOfStream] to close the [Stream]
  @override
  Stream<T> sendStreamingRequest<T>(int command, List args) {
    final streamController = StreamController<T>();
    final com = web.MessageChannel();
    _postRequest(WorkerRequest(com.port2, command, args));
    com.port1.onMessage.listen((event) {
      final res = WorkerResponse.deserialize(event.data);
      if (res.endOfStream) {
        streamController.close();
        com.port1.close();
        return;
      } else if (res.hasError) {
        streamController.addError(res.exception!);
      } else {
        streamController.add(res.result);
      }
    });
    return streamController.stream;
  }

  /// sends the [WorkerResponse] to the worker client
  /// this method must be called from the [web.Worker] only
  @override
  void reply(WorkerResponse response) {
    final message = response.serialize();
    final transfer = _getTransferables(message).toList();
    _sendPort!.postMessage(message, transfer);
  }
}

/// [Channel] used to communicate between [web.Worker]s
/// creates a [web.MessageChannel] to receive commands on [port2] and forwards them to the worker's [web.MessagePort] via [port1]
class _JsForwardChannel extends JsChannel {
  /// [remote] is the worker's [web.MessagePort]
  _JsForwardChannel(web.MessagePort remote) {
    _remote = remote;
    _com.port1.onMessage.listen(_forward);
    _sendPort = _com.port2;
  }

  /// [web.MessagePort] to the worker
  web.MessagePort? _remote;

  /// [web.MessageChannel] used for forwarding messages
  final _com = web.MessageChannel();

  /// forwards [web.MessageEvent.data] to the worker
  void _forward(web.MessageEvent e) {
    try {
      final transfer = _getTransferables(e.data).toList();
      _remote!.postMessage(e.data, transfer);
    } catch (e) {
      print('Message forwarding failed: $e');
    }
  }

  /// closes this [Channel], effectively stopping message forwarding
  @override
  void close() {
    _remote = null;
    _com.port1.close();
  }
}

/// checks if [value] is a base type value or an object
bool _isObject(dynamic value) =>
    value != null && value is! num && value is! bool && value is! String;

/// excludes base type values from [list]
Iterable<Object> _getObjects(Iterable list) =>
    list.where(_isObject).cast<Object>();

/// yields objects contained in JSON object [args] (a Map, a List, or a base type)
/// used to identify non-base type objects and provide them to [web.Worker.postMessage]
/// [web.Worker.postMessage] will clone these objects -- essentially [web.MessagePort]s
Iterable<Object> _getTransferables(dynamic args) sync* {
  if (_isObject(args)) {
    if (args is Map) args = args.values;
    if (args is! List && args is! Iterable) {
      yield args as Object;
    }

    final seen = <int>{};
    final toBeInspected = <Object>[];
    toBeInspected.addAll(_getObjects(args).where((o) => seen.add(o.hashCode)));
    var i = 0;
    while (i < toBeInspected.length) {
      final arg = toBeInspected[i++];
      if (arg is Map) {
        toBeInspected
            .addAll(_getObjects(arg.values).where((o) => seen.add(o.hashCode)));
      } else if (arg is List) {
        toBeInspected
            .addAll(_getObjects(arg).where((o) => seen.add(o.hashCode)));
      } else {
        yield arg;
      }
    }
  }
}

/// starts a [web.Worker] using the [entryPoint] and sends a start [WorkerRequest] with [startArguments]
/// the future completes after the [web.Worker]'s main program has provided the [web.MessagePort] via [JsChannel.connect]
Future<Channel> _openChannel(dynamic entryPoint, List startArguments) {
  final channel = JsChannel();
  final completer = Completer<Channel>();
  final com = web.MessageChannel();
  final message = WorkerRequest.start(com.port2, startArguments).serialize();
  final transfer = _getTransferables(message).toList();
  final worker = web.Worker(entryPoint);
  worker.postMessage(message, transfer);
  com.port1.onMessage.listen((event) {
    com.port1.close();
    channel._sendPort = event.data;
    completer.complete(channel);
  });
  return completer.future;
}

/// creates a [JsChannel] from a [web.MessagePort]
/// to be used in the [web.Worker] when the [WorkerRequest] includes a [Channel]
Channel? _deserializeChannel(dynamic channelInfo) {
  if (channelInfo == null) return null;
  final channel = JsChannel();
  channel._sendPort = channelInfo;
  return channel;
}

/// stub implementations
Future<Channel> Function(dynamic entryPoint, List startArguments)
    get openChannel => _openChannel;

Channel? Function(dynamic channelInfo) get deserializeChannel =>
    _deserializeChannel;
