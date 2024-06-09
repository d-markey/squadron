import 'dart:async';
import 'dart:js_interop';

import 'package:cancelation_token/cancelation_token.dart';
import 'package:logger/logger.dart';
import 'package:web/web.dart' as web;

import '../../cast_helpers.dart';
import '../../channel.dart';
import '../../exceptions/exception_manager.dart';
import '../../exceptions/squadron_error.dart';
import '../../exceptions/squadron_exception.dart';
import '../../exceptions/worker_exception.dart';
import '../../tokens/_squadron_cancelation_token.dart';
import '../../typedefs.dart';
import '../../worker/worker_channel.dart';
import '../../worker/worker_message.dart';
import '../../worker/worker_request.dart';
import '../../worker/worker_response.dart';
import '../../worker_service.dart';
import '../xplat/_stream_wrapper.dart';
import '../xplat/_transferables.dart';
import '../xplat/_uri_checker.dart';
import '../xplat/_user_code.dart';
import '../xplat/_value_wrapper.dart';

void _post(Logger? logger, WorkerMessage message, void Function() post) {
  try {
    post();
  } catch (ex, st) {
    logger?.e(() => 'failed to post message $message: $ex');
    throw SquadronErrorExt.create('Failed to post message: $ex', st);
  }
}

class _BaseWasmChannel {
  _BaseWasmChannel._(this._sendPort, this._logger);

  /// [web.MessagePort] to communicate with the [web.Worker] if the channel is owned by the worker owner. Otherwise,
  /// [web.MessagePort] to return values to the client.
  final web.MessagePort _sendPort;

  final Logger? _logger;

  /// [Channel] serialization in JavaScript world returns the [web.MessagePort].
  PlatformChannel serialize() => _sendPort;

  void _postRequest(WorkerRequest req) {
    req.cancelToken?.ensureStarted();
    req.wrapInPlace();
    final msg = req.jsify();
    final transfer = Transferables.get([req.channelInfo])?.jsify();
    _post(
        _logger,
        req,
        () => (transfer == null)
            ? _sendPort.postMessage(msg)
            : _sendPort.postMessage(msg, transfer as JSArray));
  }

  void _inspectAndPostRequest(WorkerRequest req) {
    req.cancelToken?.ensureStarted();
    req.wrapInPlace();
    final msg = req.jsify();
    final transfer = Transferables.get(req.data)?.jsify();
    _post(
        _logger,
        req,
        () => (transfer == null)
            ? _sendPort.postMessage(msg)
            : _sendPort.postMessage(msg, transfer as JSArray));
  }

  void _postResponse(WorkerResponse res) {
    res.wrapInPlace();
    final msg = res.jsify();
    _post(
      _logger,
      res,
      () => _sendPort.postMessage(msg),
    );
  }

  void _inspectAndPostResponse(WorkerResponse res) {
    res.wrapInPlace();
    final msg = res.jsify();
    final transfer = Transferables.get(res.data)?.jsify();
    _post(
        _logger,
        res,
        () => (transfer == null)
            ? _sendPort.postMessage(msg)
            : _sendPort.postMessage(msg, transfer as JSArray));
  }
}

/// [Channel] implementation for the JavaScript world.
class _WasmChannel extends _BaseWasmChannel implements Channel {
  _WasmChannel._(super.sendPort, super.logger, this.exceptionManager)
      : super._();

  bool _closed = false;

  final ExceptionManager exceptionManager;

  /// [Channel] sharing in JavaScript world returns a [_WasmForwardChannel].
  @override
  Channel share() => _WasmForwardChannel._(
      _sendPort, web.MessageChannel(), _logger, exceptionManager);

  /// Sends a termination [WorkerRequest] to the [web.Worker] and clears the [web.MessagePort].
  @override
  FutureOr close() {
    if (!_closed) {
      _postRequest(WorkerRequest.stop());
      _closed = true;
    }
  }

  /// Creates a [web.MessageChannel] and a [WorkerRequest] and sends it to the [web.Worker]. This method expects a
  /// single value from the [web.Worker].
  @override
  Future<T> sendRequest<T>(int command, List args,
      {CancelationToken? token,
      bool inspectRequest = false,
      bool inspectResponse = false}) {
    if (_closed) {
      throw SquadronErrorExt.create('Channel is closed');
    }
    final com = web.MessageChannel();

    final controller = StreamController<WorkerResponse>();
    com.port1.onmessage = (web.MessageEvent e) {
      controller.add(WorkerResponse(e.data.dartify() as List));
    }.toJS;

    final squadronToken = token.wrap();
    final wrapper = ValueWrapper<T>(
      WorkerRequest.userCommand(
          com.port2, command, args, squadronToken, inspectResponse),
      exceptionManager,
      _logger,
      postRequest: inspectRequest ? _inspectAndPostRequest : _postRequest,
      messages: controller.stream,
      token: squadronToken,
      cast: Cast.get<T>(),
    );
    return wrapper.compute().whenComplete(() {
      com.port1.close();
      com.port2.close();
      controller.close();
    });
  }

  /// Creates a [web.MessageChannel] and a [WorkerRequest] and sends it to the [web.Worker]. This method expects a
  /// stream of values from the [web.Worker]. The [web.Worker] must send a [WorkerResponse.endOfStream] to close
  /// the [Stream].
  @override
  Stream<T> sendStreamingRequest<T>(int command, List args,
      {SquadronCallback onDone = Channel.noop,
      CancelationToken? token,
      bool inspectRequest = false,
      bool inspectResponse = false}) {
    if (_closed) {
      throw SquadronErrorExt.create('Channel is closed');
    }
    final com = web.MessageChannel();

    final controller = StreamController<WorkerResponse>();
    com.port1.onmessage = (web.MessageEvent e) {
      controller.add(WorkerResponse(e.data.dartify() as List));
    }.toJS;

    final squadronToken = token.wrap();
    final wrapper = StreamWrapper<T>(
      WorkerRequest.userCommand(
          com.port2, command, args, squadronToken, inspectResponse),
      exceptionManager,
      _logger,
      postRequest: inspectRequest ? _inspectAndPostRequest : _postRequest,
      messages: controller.stream,
      onDone: () {
        com.port1.close();
        controller.close();
        onDone();
      },
      token: squadronToken,
      cast: Cast.get<T>(),
    );

    return wrapper.stream;
  }
}

/// [WorkerChannel] implementation for the JavaScript world.
class _WasmWorkerChannel extends _BaseWasmChannel implements WorkerChannel {
  _WasmWorkerChannel._(super.sendPort, super.logger) : super._();

  /// Sends the [web.MessagePort] to communicate with the [web.Worker]. This
  /// method must be called by the [web.Worker] upon startup.
  @override
  void connect(PlatformChannel channelInfo) => inspectAndReply(channelInfo);

  /// Sends a [WorkerResponse] with the specified data to the worker client.
  /// This method must be called from the [web.Worker] only. On Web patforms,
  /// this version does not check arguments for transferable objects.
  @override
  void reply(dynamic data) => _postResponse(WorkerResponse.withResult(data));

  /// Sends a [WorkerResponse] with the specified data to the worker client.
  /// This method must be called from the [web.Worker] only. On Web patforms,
  /// this version (tentatively) checks arguments for transferable objects.
  @override
  void inspectAndReply(dynamic data) =>
      _inspectAndPostResponse(WorkerResponse.withResult(data));

  @override
  void log(LogEvent message) => _postResponse(WorkerResponse.log(message));

  /// Checks if [stream] can be streamed back to the worker client. Returns
  /// `true` for browser platforms.
  @override
  bool canStream(Stream<dynamic> stream) => true;

  /// Sends a [WorkerResponse.closeStream] to the worker client. This method
  /// must be called from the [web.Worker] only.
  @override
  void closeStream() => _postResponse(WorkerResponse.closeStream());

  /// Sends the [WorkerResponse] to the worker client. This method must be
  /// called from the [web.Worker] only.
  @override
  void error(SquadronException error) {
    _logger?.t(() => 'replying with error: ${error.runtimeType} $error');
    _postResponse(WorkerResponse.withError(error));
  }
}

/// [Channel] used to communicate between [web.Worker]s. Creates a
/// [web.MessageChannel] to receive commands on
/// [web.MessageChannel.port2] and forwards them to the worker's [web.MessagePort] via [web.MessageChannel.port1].
class _WasmForwardChannel extends _WasmChannel {
  /// [_remote] is the worker's [web.MessagePort], [_com] is the intermediate
  /// message channel
  _WasmForwardChannel._(this._remote, this._com, Logger? logger,
      ExceptionManager exceptionManager)
      : super._(_com.port2, logger, exceptionManager) {
    _com.port1.onmessage = _forward.toJS;
  }

  /// [web.MessagePort] to the worker.
  final web.MessagePort _remote;

  /// [web.MessageChannel] used for forwarding messages.
  final web.MessageChannel _com;

  /// Forwards [web.MessageEvent.data] to the worker.
  void _forward(web.MessageEvent e) {
    if (_closed) {
      throw SquadronErrorExt.create('Channel is closed');
    }
    final message = WorkerRequest(e.data.dartify() as List);
    final transfer = Transferables.get(message.data)?.jsify();
    _post(
        _logger,
        message,
        () => (transfer == null)
            ? _remote.postMessage(e.data)
            : _sendPort.postMessage(e.data, transfer as JSArray));
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

/// Starts a [web.Worker] using the [entryPoint] and sends a start
/// [WorkerRequest] with [startArguments]. The future completes after the
/// [web.Worker]'s main program has provided the [web.MessagePort] via
/// [_WasmWorkerChannel.connect].
Future<Channel> openChannel(EntryPoint entryPoint,
    ExceptionManager exceptionManager, Logger? logger, List startArguments,
    [PlatformThreadHook? hook]) async {
  final completer = Completer<Channel>();
  final com = web.MessageChannel();
  final worker = web.Worker(entryPoint);

  final ready = Completer<void>();

  worker.onerror = (JSAny? event) {
    if (!ready.isCompleted) {
      ready.complete();
    }

    UriChecker.exists(Uri.parse(entryPoint)).then((found) {
      String msg;
      if (event.isA<web.ErrorEvent>()) {
        final error = event as web.ErrorEvent;
        msg =
            '$entryPoint => ${error.runtimeType} ${error.message} [${error.filename}(${error.lineno})]';
      } else {
        msg = '$entryPoint: ${event.runtimeType} $event';
      }
      if (!found) {
        msg = '!! WARNING: it seems no Web Worker lives at $msg';
      }
      final error = WorkerException(msg);
      logger?.e(() => 'unhandled error from Web Worker: ${error.message}.');
      if (!found) {
        logger?.e(() => 'it seems no Web Worker lives at $entryPoint.');
      }
      if (!completer.isCompleted) {
        completer.completeError(error, error.stackTrace);
      }
    });
  }.toJS;

  worker.onmessage = (JSAny? msg) {
    if (!ready.isCompleted) {
      ready.complete();
    }
  }.toJS;
  await ready.future;
  worker.onmessage = null;

  final startRequest = WorkerRequest.start(com.port2, startArguments);

  com.port1.onmessage = (web.MessageEvent event) {
    final response = WorkerResponse(event.data.dartify() as List);
    if (!response.unwrapInPlace(exceptionManager, logger)) {
      return;
    }

    if (!completer.isCompleted) {
      final error = response.error;
      if (error != null) {
        logger?.e(() => 'connection to Web Worker failed: ${response.error}');
        completer.completeError(error, error.stackTrace);
        worker.terminate();
      } else {
        logger?.t('connected to Web Worker');
        final channel =
            _WasmChannel._(response.result, logger, exceptionManager);
        completer.complete(channel);
      }
    } else {
      logger?.d(() => 'unexpected response: $response');
    }
  }.toJS;

  startRequest.wrapInPlace();
  final msg = startRequest.jsify();
  final transfer = Transferables.get(startRequest.data)?.jsify();
  try {
    _post(
        logger,
        startRequest,
        () => (transfer == null)
            ? worker.postMessage(msg)
            : worker.postMessage(msg, transfer as JSArray));
  } catch (ex, st) {
    com.port1.close();
    com.port2.close();
    worker.terminate();
    logger
        ?.e(() => 'failed to post connection request $startRequest: error $ex');
    completer.completeError(SquadronException.from(ex, st), st);
  }

  final channel = await completer.future;

  if (hook != null) {
    final hookRes = UserCode.run(
      logger,
      () => hook(worker),
      'PlatforWorkerHook for $entryPoint',
    );
    if (hookRes is Future) {
      await hookRes;
    }
  }

  logger?.t('created Web Worker');

  return channel;
}

/// Creates a [_WasmChannel] from a [web.MessagePort].
Channel? deserializeChannel(PlatformChannel? channelInfo, Logger? logger,
        ExceptionManager exceptionManager) =>
    (channelInfo == null)
        ? null
        : _WasmChannel._(channelInfo, logger, exceptionManager);

/// Creates a [_WasmWorkerChannel] from a [web.MessagePort].
WorkerChannel? deserializeWorkerChannel(
        PlatformChannel? channelInfo, Logger? logger) =>
    (channelInfo == null) ? null : _WasmWorkerChannel._(channelInfo, logger);
