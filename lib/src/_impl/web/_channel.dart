import 'dart:async';
import 'dart:js_interop';

import 'package:logger/web.dart';
import 'package:meta/meta.dart';
import 'package:web/web.dart' as web;

import '../../build_options.dart';
import '../../channel.dart';
import '../../exceptions/exception_manager.dart';
import '../../exceptions/squadron_error.dart';
import '../../exceptions/squadron_exception.dart';
import '../../exceptions/task_terminated_exception.dart';
import '../../exceptions/worker_exception.dart';
import '../../squadron_singleton.dart';
import '../../tokens/_squadron_cancelation_token.dart';
import '../../utils.dart';
import '../../worker/entry_point.dart';
import '../../worker/worker_channel.dart';
import '../../worker/worker_message.dart';
import '../../worker/worker_request.dart';
import '../../worker/worker_response.dart';
import '../xplat/_disconnected_channel.dart';
import '../xplat/_result_stream.dart';
import '_event_buffer.dart';
import '_patch.dart';
import '_typedefs.dart';
import '_uri_checker.dart';
import '_web_entry_point_uri.dart';
import 'entry_point.dart';

part '_channel_forward.dart';
part '_channel_impl.dart';

/// Stub implementations

/// Starts a [web.Worker] using the [entryPoint] and sends a start
/// [WorkerRequest] with [startArguments]. The future completes after the
/// [web.Worker]'s main program has provided the [web.MessagePort] via
/// [WorkerChannel.connect].
Future<Channel> openChannel(
  EntryPoint entryPoint,
  ExceptionManager exceptionManager,
  Logger? logger,
  List startArguments,
  WebPlatformThreadHook? hook,
) async {
  if (entryPoint is! WebEntryPoint) {
    throw UnsupportedError(
        'Unsupported Web entry point: ${entryPoint.runtimeType}');
  }

  if (!BuildOptions.withInternalLogging) {
    logger = null;
  }

  final completer = Completer<_WebChannel>();
  final ready = Completer<bool>();
  Channel? channel;

  final com = web.MessageChannel();
  final webEntryPoint = WebEntryPointUri.from(
    entryPoint,
    addRandomHash: Squadron.disableBrowserCache,
  );
  late web.Worker worker;

  void $failure(SquadronException ex) {
    ready.safeCompleteError(ex);
    completer.safeCompleteError(ex);
  }

  void $success(_WebChannel channel) {
    if (!ready.isCompleted) {
      throw SquadronErrorImpl.create('Invalid state: worker is not ready');
    }
    completer.safeComplete(channel);
  }

  try {
    worker = web.Worker(webEntryPoint.uri.toJS);

    void $errorHandler(web.ErrorEvent? e) {
      final err = e.$dartError,
          error = SquadronErrorImpl.create(err.toString());
      logger?.e(() => 'Connection to Web Worker failed: $error');
      $failure(error);

      final uri = Uri.parse(webEntryPoint.uri);
      UriChecker.exists(uri).then((found) {
        try {
          final msg = (e != null)
              ? '${webEntryPoint.uri} => ${err.runtimeType} $err [${e.filename}(${e.lineno})]'
              : '${webEntryPoint.uri} => ${err.runtimeType} $err';
          logger?.e(() => 'Unhandled error from Web Worker: $msg.');
          if (!found) {
            logger?.e(
                () => 'It seems no Web Worker lives at ${webEntryPoint.uri}.');
          }
        } catch (_) {
          // ignore
        }
      });
    }

    worker.onerror = $errorHandler.toJS;
    worker.onmessageerror = $errorHandler.toJS;

    final disconnected = DisconnectedChannel(exceptionManager, logger);

    worker.onmessage = (web.MessageEvent? e) {
      try {
        final response = WorkerResponse.from(e.$dartData!);
        if (!response.unwrapInPlace(disconnected)) {
          return;
        }

        final error = response.error;
        if (error != null) {
          logger?.e(() => 'Connection to Web Worker failed: $error');
          $failure(error);
        } else if (!ready.isCompleted) {
          logger?.t('Web Worker is ready');
          ready.complete(response.result);
        }
      } catch (ex, st) {
        return $failure(SquadronException.from(ex, st));
      }
    }.toJS;

    final res = await ready.future;
    if (!res) {
      throw SquadronErrorImpl.create('Web Worker is not ready');
    }

    final startRequest = WorkerRequest.start(com.port2, startArguments);

    com.port1.onmessage = (web.MessageEvent e) {
      final response = WorkerResponse.from(e.$dartData!);
      if (!response.unwrapInPlace(disconnected)) {
        return;
      }

      final error = response.error;
      if (error != null) {
        logger?.e(() => 'Connection to Web Worker failed: $error');
        $failure(error);
      } else if (response.endOfStream) {
        logger?.w('Disconnecting from Web Worker');
        channel?.close();
      } else if (!completer.isCompleted) {
        logger?.t('Connected to Web Worker');
        final webCh = _WebChannel._(response.result, logger, exceptionManager);
        webCh._thread = worker;
        channel = webCh;
        $success(webCh);
      } else {
        logger?.d(() => 'Unexpected response: $response');
      }
    }.toJS;

    try {
      final transfer = JSArray();
      startRequest.wrapInPlace();
      final msg = $jsify(startRequest, transfer);
      worker.postMessage(msg, transfer);
    } catch (ex, st) {
      logger?.e(() => 'Failed to post connection request $startRequest: $ex');
      throw SquadronErrorImpl.create(
          'Failed to post connection request: $ex', st);
    }

    try {
      final channel = await completer.future;
      if (hook != null) {
        final res = hook.call(worker);
        if (res is Future) await res;
      }
      logger?.t('Created Web Worker for $entryPoint');
      return channel;
    } catch (ex) {
      logger?.e(() => 'Connection to Web Worker failed: $ex');
      rethrow;
    }
  } catch (ex, st) {
    ready.future.ignore();
    completer.future.ignore();
    logger?.t('Failed to create Web Worker for $entryPoint');
    com.port1.close();
    com.port2.close();
    worker.terminate();
    throw SquadronException.from(ex, st);
  } finally {
    webEntryPoint.release();
  }
}

@internal
int getActiveConnections(Channel channel) =>
    (channel is _WebChannel) ? channel._activeConnections.length : 0;

@internal
void terminateChannel(Channel channel, TaskTerminatedException ex) {
  if (channel is _WebChannel) {
    channel._thread?.terminate();
    final pendingConnections = channel._activeConnections;
    for (var c in pendingConnections) {
      c.safeAddError(ex);
      c.close();
    }
  }
}

/// Creates a [_WebChannel] from a [web.MessagePort].
Channel? deserialize(
  WebPlatformChannel? channelInfo, [
  Logger? logger,
  ExceptionManager? exceptionManager,
]) =>
    (channelInfo == null)
        ? null
        : _WebChannel._(
            channelInfo,
            logger,
            exceptionManager ?? ExceptionManager(),
          );
