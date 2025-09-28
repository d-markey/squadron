import 'dart:async';
import 'dart:js_interop';

import 'package:logger/web.dart';
import 'package:meta/meta.dart';
import 'package:web/web.dart' as web;

import '../../channel.dart';
import '../../exceptions/exception_manager.dart';
import '../../exceptions/squadron_error.dart';
import '../../exceptions/squadron_exception.dart';
import '../../exceptions/task_terminated_exception.dart';
import '../../exceptions/worker_exception.dart';
import '../../tokens/_squadron_cancelation_token.dart';
import '../../worker/worker_channel.dart';
import '../../worker/worker_request.dart';
import '../../worker/worker_response.dart';
import '../xplat/_disconnected_channel.dart';
import '../xplat/_result_stream.dart';
import '_entry_point_uri.dart';
import '_event_buffer.dart';
import '_patch.dart';
import '_typedefs.dart';
import '_uri_checker.dart';

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
  PlatformThreadHook? hook,
) async {
  final completer = Completer<_WebChannel>();
  final ready = Completer<bool>();
  Channel? channel;

  final com = web.MessageChannel();
  final webEntryPoint = EntryPointUri.from(entryPoint);
  late web.Worker worker;

  void fail(SquadronException ex) {
    if (!ready.isCompleted) ready.completeError(ex);
    if (!completer.isCompleted) completer.completeError(ex);
  }

  void success(_WebChannel channel) {
    if (!ready.isCompleted) {
      throw SquadronErrorImpl.create('Invalid state: worker is not ready');
    }
    if (!completer.isCompleted) completer.complete(channel);
  }

  try {
    worker = web.Worker(webEntryPoint.uri.toJS);

    void $errorHandler(web.ErrorEvent? e) {
      final err = e.$dartError,
          error = SquadronErrorImpl.create(err.toString());
      logger?.e(() => 'Connection to Web Worker failed: $error');
      fail(error);

      UriChecker.exists(entryPoint).then((found) {
        try {
          final msg = (e != null)
              ? '$entryPoint => ${err.runtimeType} $err [${e.filename}(${e.lineno})]'
              : '$entryPoint => ${err.runtimeType} $err';
          logger?.e(() => 'Unhandled error from Web Worker: $msg.');
          if (!found) {
            logger?.e(() => 'It seems no Web Worker lives at $entryPoint.');
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
        final response = WorkerResponseImpl.from(e.$dartData!);
        if (!response.unwrapInPlace(disconnected)) {
          return;
        }

        final error = response.error;
        if (error != null) {
          logger?.e(() => 'Connection to Web Worker failed: $error');
          fail(error);
        } else if (!ready.isCompleted) {
          logger?.t('Web Worker is ready');
          ready.complete(response.result);
        }
      } catch (ex, st) {
        return fail(SquadronException.from(ex, st));
      }
    }.toJS;

    final res = await ready.future;
    if (!res) {
      throw SquadronErrorImpl.create('Web Worker is not ready');
    }

    final startRequest = WorkerRequest.start(com.port2, startArguments);

    com.port1.onmessage = (web.MessageEvent e) {
      final response = WorkerResponseImpl.from(e.$dartData!);
      if (!response.unwrapInPlace(disconnected)) {
        return;
      }

      final error = response.error;
      if (error != null) {
        logger?.e(() => 'Connection to Web Worker failed: $error');
        fail(error);
      } else if (response.endOfStream) {
        logger?.w('Disconnecting from Web Worker');
        channel?.close();
      } else if (!completer.isCompleted) {
        logger?.t('Connected to Web Worker');
        final webCh = _WebChannel._(response.result, logger, exceptionManager);
        webCh._thread = worker;
        channel = webCh;
        success(webCh);
      } else {
        logger?.d(() => 'Unexpected response: $response');
      }
    }.toJS;

    try {
      final transfer = JSArray();
      final msg = $jsify(startRequest.wrapInPlace(), transfer);
      worker.postMessage(msg, transfer);
    } catch (ex, st) {
      logger?.e(() => 'Failed to post connection request $startRequest: $ex');
      throw SquadronErrorImpl.create(
          'Failed to post connection request: $ex', st);
    }

    try {
      final channel = await completer.future;
      if (hook != null) {
        await hook.call(worker);
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
      c.addError(ex);
      c.close();
    }
  }
}

/// Creates a [_WebChannel] from a [web.MessagePort].
Channel? deserialize(
  PlatformChannel? channelInfo, [
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
