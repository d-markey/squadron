import 'dart:async';
import 'dart:js_interop';

import 'package:cancelation_token/cancelation_token.dart';
import 'package:logger/logger.dart';
import 'package:web/web.dart' as web;

import '../../channel.dart';
import '../../exceptions/exception_manager.dart';
import '../../exceptions/squadron_error.dart';
import '../../exceptions/squadron_exception.dart';
import '../../exceptions/worker_exception.dart';
import '../../tokens/_squadron_cancelation_token.dart';
import '../../typedefs.dart';
import '../../worker/worker_channel.dart';
import '../../worker/worker_request.dart';
import '../../worker/worker_response.dart';
import '../../worker_service.dart';
import '../xplat/_stream_wrapper.dart';
import '../xplat/_value_wrapper.dart';
import '_transferables.dart';
import '_uri_checker.dart';

class _BaseJsChannel {
  _BaseJsChannel._(this._sendPort, this._logger);

  /// [web.MessagePort] to communicate with the [web.Worker] if the channel is owned by the worker owner. Otherwise,
  /// [web.MessagePort] to return values to the client.
  final web.MessagePort _sendPort;

  final Logger? _logger;

  /// [Channel] serialization in JavaScript world returns the [web.MessagePort].
  PlatformChannel serialize() => _sendPort;

  void _postRequest(WorkerRequest req) {
    req.cancelToken?.ensureStarted();
    req.wrapInPlace();
    try {
      final channelInfo = req.channelInfo;
      if (channelInfo == null) {
        _sendPort.postMessage(req.jsify());
      } else {
        _sendPort.postMessage(req.jsify(), [channelInfo].jsify() as JSArray);
      }
    } on UnimplementedError catch (ex, st) {
      _logger?.e(() => 'failed to post request $req: $ex');
      throw SquadronErrorExt.create(ex.message ?? 'Unimplemented', st);
    } catch (ex, st) {
      _logger?.e(() => 'failed to post request $req: $ex');
      throw SquadronException.from(ex, st);
    }
  }

  void _inspectAndPostRequest(WorkerRequest req) {
    req.cancelToken?.ensureStarted();
    req.wrapInPlace();
    try {
      _sendPort.postMessage(
        req.jsify(),
        Transferables.get(req).toList().jsify() as JSArray,
      );
    } on UnimplementedError catch (ex, st) {
      _logger?.e(() => 'failed to post request $req: $ex');
      throw SquadronErrorExt.create(
          ex.message ?? 'message contains untransferable objects', st);
    } catch (ex, st) {
      _logger?.e(() => 'failed to post request $req: $ex');
      throw SquadronException.from(ex, st);
    }
  }

  void _postResponse(WorkerResponse res) {
    res.wrapInPlace();
    try {
      _sendPort.postMessage(res.jsify());
    } on UnimplementedError catch (ex, st) {
      _logger?.e(() => 'failed to post response $res: $ex');
      throw SquadronErrorExt.create(
          ex.message ?? 'message contains untransferable objects', st);
    } catch (ex, st) {
      _logger?.e(() => 'failed to post response $res: $ex');
      throw SquadronException.from(ex, st);
    }
  }

  void _inspectAndPostResponse(WorkerResponse res) {
    res.wrapInPlace();
    try {
      _sendPort.postMessage(
        res.jsify(),
        Transferables.get(res).toList().jsify() as JSArray,
      );
    } on UnimplementedError catch (ex, st) {
      _logger?.e(() => 'failed to post response $res: $ex');
      throw SquadronErrorExt.create(
          ex.message ?? 'message contains untransferable objects', st);
    } catch (ex, st) {
      _logger?.e(() => 'failed to post response $res: $ex');
      throw SquadronException.from(ex, st);
    }
  }
}

/// [Channel] implementation for the JavaScript world.
class _JsChannel extends _BaseJsChannel implements Channel {
  _JsChannel._(super.sendPort, super.logger, this.exceptionManager) : super._();

  bool _closed = false;

  final ExceptionManager exceptionManager;

  /// [Channel] sharing in JavaScript world returns a [_JsForwardChannel].
  @override
  Channel share() => _JsForwardChannel._(
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
      throw SquadronErrorExt.create('Channel is closed', StackTrace.current);
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
      postMethod: inspectRequest ? _inspectAndPostRequest : _postRequest,
      messages: controller.stream,
      token: squadronToken,
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
      throw SquadronErrorExt.create('Channel is closed', StackTrace.current);
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
      postMethod: inspectRequest ? _inspectAndPostRequest : _postRequest,
      messages: controller.stream,
      onDone: () {
        com.port1.close();
        controller.close();
        onDone();
      },
      token: squadronToken,
    );

    return wrapper.stream;
  }
}

/// [WorkerChannel] implementation for the JavaScript world.
class _JsWorkerChannel extends _BaseJsChannel implements WorkerChannel {
  _JsWorkerChannel._(super.sendPort, super.logger) : super._();

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
    _logger?.t(() => 'replying with error: $error');
    _postResponse(WorkerResponse.withError(error));
  }
}

/// [Channel] used to communicate between [web.Worker]s. Creates a
/// [web.MessageChannel] to receive commands on
/// [web.MessageChannel.port2] and forwards them to the worker's [web.MessagePort] via [web.MessageChannel.port1].
class _JsForwardChannel extends _JsChannel {
  /// [_remote] is the worker's [web.MessagePort], [_com] is the intermediate
  /// message channel
  _JsForwardChannel._(this._remote, this._com, Logger? logger,
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
      throw SquadronErrorExt.create('Channel is closed', StackTrace.current);
    }
    final message = WorkerRequest(e.data.dartify() as List);
    try {
      _remote.postMessage(
        message.jsify(),
        Transferables.get(message).toList().jsify() as JSArray,
      );
    } catch (ex, st) {
      _logger?.e(() => 'failed to forward $message: error $ex');
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

/// Starts a [web.Worker] using the [entryPoint] and sends a start
/// [WorkerRequest] with [startArguments]. The future completes after the
/// [web.Worker]'s main program has provided the [web.MessagePort] via
/// [_JsWorkerChannel.connect].
Future<Channel> openChannel(EntryPoint entryPoint,
    ExceptionManager exceptionManager, Logger? logger, List startArguments,
    [PlatformThreadHook? hook]) async {
  final completer = Completer<Channel>();
  final com = web.MessageChannel();
  final worker = web.Worker(entryPoint);

  dbgTrace('Loading Web Worker $entryPoint');

  final ready = Completer<void>();

  worker.onerror = (JSAny? event) {
    dbgTrace('Worker $entryPoint reported an error: $event');
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
        msg = '!! WARNING: it seems no worker code lives at $msg';
      }
      final error = WorkerException(msg);
      logger?.e(() => 'Unhandled error from Web worker: ${error.message}.');
      if (!found) {
        logger?.e(() => 'It seems no worker code lives at $entryPoint.');
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
  dbgTrace('Worker $entryPoint is now ready');
  worker.onmessage = null;

  dbgTrace('Worker $entryPoint: hook = $hook');

  try {
    hook?.call(worker);
  } catch (ex) {
    logger?.e(() =>
        'An exception occurred in PlatforWorkerHook for $entryPoint: $ex');
  }

  final startRequest = WorkerRequest.start(com.port2, startArguments);

  logger?.t(() => 'created Web Worker');

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
        logger?.t(() => 'connected to Web Worker');
        final channel = _JsChannel._(response.result, logger, exceptionManager);
        completer.complete(channel);
      }
    } else {
      logger?.d(() => 'unexpected response: $response');
    }
  }.toJS;

  dbgTrace('Worker $entryPoint: sending $startRequest');
  startRequest.wrapInPlace();
  try {
    worker.postMessage(
      startRequest.jsify(),
      Transferables.get(startRequest).toList().jsify() as JSArray,
    );
  } catch (ex, st) {
    com.port1.close();
    com.port2.close();
    worker.terminate();
    logger
        ?.e(() => 'failed to post connection request $startRequest: error $ex');
    completer.completeError(SquadronException.from(ex, st), st);
  }
  return completer.future;
}

/// Creates a [_JsChannel] from a [web.MessagePort].
Channel? deserializeChannel(PlatformChannel? channelInfo, Logger? logger,
        ExceptionManager exceptionManager) =>
    (channelInfo == null)
        ? null
        : _JsChannel._(channelInfo, logger, exceptionManager);

/// Creates a [_JsWorkerChannel] from a [web.MessagePort].
WorkerChannel? deserializeWorkerChannel(
        PlatformChannel? channelInfo, Logger? logger) =>
    (channelInfo == null) ? null : _JsWorkerChannel._(channelInfo, logger);
