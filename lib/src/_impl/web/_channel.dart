import 'dart:async';
import 'dart:js_interop';

import 'package:logger/logger.dart';
import 'package:meta/meta.dart';
import 'package:web/web.dart' as web;

import '../../../squadron.dart';
import '../../exceptions/squadron_error.dart';
import '../../tokens/_squadron_cancelation_token.dart';
import '../../worker/worker_request.dart';
import '../../worker/worker_response.dart';
import '../xplat/_stream_wrapper.dart';
import '../xplat/_transferables.dart';
import '../xplat/_uri_checker.dart';
import '../xplat/_user_code.dart';
import '../xplat/_value_wrapper.dart';
import '_patch.dart';

class _BaseWebChannel {
  _BaseWebChannel._(this._sendPort, this._logger);

  /// [web.MessagePort] to communicate with the [web.Worker] if the channel is owned by the worker owner. Otherwise,
  /// [web.MessagePort] to return values to the client.
  final web.MessagePort _sendPort;

  final Logger? _logger;

  /// [Channel] serialization in JavaScript world returns the [web.MessagePort].
  PlatformChannel serialize() => _sendPort;

  void _postRequest(WorkerRequest req) {
    try {
      req.cancelToken?.ensureStarted();
      final data = req.wrapInPlace();
      final msg = data.jsify();
      final transfer = Transferables.get([req.channelInfo]);
      if (transfer == null || transfer.isEmpty) {
        _sendPort.postMessage(msg);
      } else {
        final jsTransfer = transfer.jsify() as JSArray;
        _sendPort.postMessage(msg, jsTransfer);
      }
    } catch (ex, st) {
      _logger?.e(() => 'failed to post message $req: $ex');
      throw SquadronErrorExt.create('Failed to post message: $ex', st);
    }
  }

  void _inspectAndPostRequest(WorkerRequest req) {
    try {
      req.cancelToken?.ensureStarted();
      final data = req.wrapInPlace();
      final msg = data.jsify();
      final transfer = Transferables.get(data);
      if (transfer == null || transfer.isEmpty) {
        _sendPort.postMessage(msg);
      } else {
        final jsTransfer = transfer.jsify() as JSArray;
        _sendPort.postMessage(msg, jsTransfer);
      }
    } catch (ex, st) {
      _logger?.e(() => 'failed to post message $req: $ex');
      throw SquadronErrorExt.create('Failed to post message: $ex', st);
    }
  }

  void _postResponse(WorkerResponse res) {
    try {
      final data = res.wrapInPlace();
      final msg = data.jsify();
      _sendPort.postMessage(msg);
    } catch (ex, st) {
      _logger?.e(() => 'failed to post message $res: $ex');
      throw SquadronErrorExt.create('Failed to post message: $ex', st);
    }
  }

  void _inspectAndPostResponse(WorkerResponse res) {
    try {
      final data = res.wrapInPlace();
      final msg = data.jsify();
      final transfer = Transferables.get(data);
      if (transfer == null || transfer.isEmpty) {
        _sendPort.postMessage(msg);
      } else {
        final jsTransfer = transfer.jsify() as JSArray;
        _sendPort.postMessage(msg, jsTransfer);
      }
    } catch (ex, st) {
      _logger?.e(() => 'failed to post message $res: $ex');
      throw SquadronErrorExt.create('Failed to post message: $ex', st);
    }
  }
}

/// [Channel] implementation for the JavaScript world.
class _WebChannel extends _BaseWebChannel implements Channel {
  _WebChannel._(super.sendPort, super.logger, this.exceptionManager)
      : super._();

  bool _closed = false;

  final ExceptionManager exceptionManager;

  /// [Channel] sharing in JavaScript world returns a [_WebForwardChannel].
  @override
  Channel share() => _WebForwardChannel._(
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

    final controller = StreamController<WorkerResponse>();

    final com = web.MessageChannel();
    com.port1.onmessageerror = (web.ErrorEvent e) {
      var err = getErrorEventError(e);
      err = SquadronErrorExt.create(err?.toString() ?? getErrorEventMessage(e));
      controller.addError(err);
    }.toJS;
    com.port1.onmessage = (web.MessageEvent e) {
      final data = getMessageEventData(e) as List;
      controller.add(WorkerResponseExt.from(data));
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

    final controller = StreamController<WorkerResponse>();

    final com = web.MessageChannel();
    com.port1.onmessage = (web.MessageEvent e) {
      final msg = getMessageEventData(e) as List;
      controller.add(WorkerResponseExt.from(msg));
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
class _WebWorkerChannel extends _BaseWebChannel implements WorkerChannel {
  _WebWorkerChannel._(super.sendPort, super.logger) : super._();

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
class _WebForwardChannel extends _WebChannel {
  /// [_remote] is the worker's [web.MessagePort], [_com] is the intermediate
  /// message channel
  _WebForwardChannel._(this._remote, this._com, Logger? logger,
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
    try {
      final data = getMessageEventData(e) as List;
      final transfer = Transferables.get(data);
      if (transfer == null || transfer.isEmpty) {
        _remote.postMessage(e.data);
      } else {
        final jsTransfer = transfer.jsify() as JSArray;
        _remote.postMessage(e.data, jsTransfer);
      }
    } catch (ex, st) {
      _logger?.e(() => 'failed to post message $e: $ex');
      throw SquadronErrorExt.create('Failed to post message: $ex', st);
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
/// [_WebWorkerChannel.connect].
Future<Channel> openChannel(EntryPoint entryPoint,
    ExceptionManager exceptionManager, Logger? logger, List startArguments,
    [PlatformThreadHook? hook]) async {
  final completer = Completer<Channel>();
  final ready = Completer<void>();

  final com = web.MessageChannel();
  final webEntryPoint = getEntryPointUrl(entryPoint);
  late web.Worker worker;

  void fail(SquadronException ex) {
    if (!ready.isCompleted) ready.completeError(ex);
    if (!completer.isCompleted) completer.completeError(ex);
  }

  void success(Channel channel) {
    if (!ready.isCompleted) {
      throw SquadronErrorExt.create('Invalid state: worker is not ready');
    }
    if (!completer.isCompleted) completer.complete(channel);
  }

  try {
    worker = web.Worker(webEntryPoint.url);
    setDbgId(worker, '${webEntryPoint.url}#');

    worker.onerror = (web.ErrorEvent? e) {
      var err = getErrorEventError(e);
      if (err is List) {
        err = exceptionManager.deserialize(err);
      }
      final error = (err != null)
          ? SquadronException.from(err)
          : SquadronErrorExt.create('Unexpected error');
      logger?.e(() => 'connection to Web Worker failed: $error');
      fail(error);

      UriChecker.exists(entryPoint).then((found) {
        String msg;
        if (e != null) {
          msg =
              '$entryPoint => ${e.runtimeType} $e [${e.filename}(${e.lineno})]';
        } else {
          msg = '$entryPoint: ${e.runtimeType} $e';
        }
        if (!found) {
          msg = '!! WARNING: it seems no Web Worker lives at $msg';
        }
        logger?.e(() => 'unhandled error from Web Worker: $msg.');
        if (!found) {
          logger?.e(() => 'it seems no Web Worker lives at $entryPoint.');
        }
      });
    }.toJS;
    worker.onmessageerror = worker.onerror;

    worker.onmessage = (web.MessageEvent? e) {
      try {
        final msg = getMessageEventData(e) as List;
        final response = WorkerResponseExt.from(msg);
        if (!response.unwrapInPlace(exceptionManager, logger)) {
          return;
        }

        final error = response.error;
        if (error != null) {
          logger?.e(() => 'connection to Web Worker failed: $error');
          return fail(error);
        } else if (!ready.isCompleted) {
          ready.complete();
        }
      } catch (ex, st) {
        return fail(SquadronErrorExt.create(ex.toString(), st));
      }
    }.toJS;

    await ready.future;

    final startRequest = WorkerRequest.start(com.port2, startArguments);

    com.port1.onmessage = (web.MessageEvent e) {
      final msg = getMessageEventData(e) as List;
      final response = WorkerResponseExt.from(msg);
      if (!response.unwrapInPlace(exceptionManager, logger)) {
        return;
      }

      if (!completer.isCompleted) {
        final error = response.error;
        if (error != null) {
          logger?.e(() => 'connection to Web Worker failed: $error');
          fail(error);
        } else {
          logger?.t('connected to Web Worker');
          final channel =
              _WebChannel._(response.result, logger, exceptionManager);
          success(channel);
        }
      } else {
        logger?.d(() => 'unexpected response: $response');
      }
    }.toJS;

    try {
      final data = startRequest.wrapInPlace();
      final msg = data.jsify();
      final transfer = Transferables.get(data);
      if (transfer == null || transfer.isEmpty) {
        worker.postMessage(msg);
      } else {
        final jsTransfer = transfer.jsify() as JSArray;
        worker.postMessage(msg, jsTransfer);
      }
    } catch (ex, st) {
      logger?.e(() => 'failed to post message $startRequest: $ex');
      throw SquadronErrorExt.create('Failed to post message: $ex', st);
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

    logger?.t('created Web Worker for $entryPoint');

    return channel;
  } catch (_) {
    logger?.t('failed to create Web Worker for $entryPoint');
    com.port1.close();
    com.port2.close();
    worker.terminate();
    rethrow;
  } finally {
    if (webEntryPoint.revoke) {
      web.URL.revokeObjectURL(webEntryPoint.url);
    }
  }
}

/// Creates a [_WebChannel] from a [web.MessagePort].
Channel? deserializeChannel(PlatformChannel? channelInfo, Logger? logger,
        ExceptionManager exceptionManager) =>
    (channelInfo == null)
        ? null
        : _WebChannel._(channelInfo, logger, exceptionManager);

/// Creates a [_WebWorkerChannel] from a [web.MessagePort].
WorkerChannel? deserializeWorkerChannel(
        PlatformChannel? channelInfo, Logger? logger) =>
    (channelInfo == null) ? null : _WebWorkerChannel._(channelInfo, logger);

@internal
({String url, bool revoke}) getEntryPointUrl(Uri workerEntrypoint) {
  final fileName =
      workerEntrypoint.pathSegments.lastOrNull?.toString().toLowerCase() ?? '';
  if (fileName.endsWith('.js') || fileName.endsWith('.mjs')) {
    // a JavaScript worker
    return (url: workerEntrypoint.toString(), revoke: false);
  } else if (fileName.endsWith('.wasm')) {
    // blob containing the JavaScript code to load and invoke the Web Assembly worker
    final blob = web.Blob(
      [_wasmLoaderScript(workerEntrypoint.toString()).toJS].toJS,
      web.BlobPropertyBag(type: 'application/javascript'),
    );
    return (url: web.URL.createObjectURL(blob), revoke: true);
  } else if (workerEntrypoint.isScheme('data') ||
      workerEntrypoint.isScheme('javascript')) {
    // something else, eg. inline JavaScript
    return (url: workerEntrypoint.toString(), revoke: false);
  } else {
    throw SquadronErrorExt.create('Invalid entry point URI');
  }
}

String _wasmLoaderScript(String url) => '''(async function() {
  try {
    let dart2wasm_runtime; let moduleInstance;
    const workerUri = new URL("$url", self.location.origin).href;
    const runtimeUri = workerUri.replaceAll('.unopt', '').replaceAll('.wasm', '.mjs');
    try {
      const dartModule = WebAssembly.compileStreaming(fetch(workerUri));
      dart2wasm_runtime = await import(runtimeUri);
      moduleInstance = await dart2wasm_runtime.instantiate(dartModule, {});
    } catch (exception) {
      console.error(`Failed to fetch and instantiate wasm module \${workerUri}: \${exception}`);
      console.error('See https://dart.dev/web/wasm for more information.');
      throw new Error(`Worker \${workerUri}: \${exception.message ?? 'Unknown error when instantiating worker module'}`);
    }
    try {
      await dart2wasm_runtime.invoke(moduleInstance);
      console.log(`Succesfully loaded and invoked \${workerUri}`);
    } catch (exception) {
      console.error(`Exception while invoking wasm module \${workerUri}: \${exception}`);
      throw new Error(`Worker \${workerUri}: \${exception.message ?? 'Unknown error when invoking worker module'}`);
    }
  } catch (ex) {
    const ts = (Date.now() - Date.UTC(2020, 1, 2)) * 1000;
    postMessage([ts, null, ["\$sqdrn", `Unexpected error: \${ex}`, null], null, null]);
  }
})()''';
