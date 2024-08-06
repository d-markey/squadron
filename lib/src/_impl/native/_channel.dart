import 'dart:async';
import 'dart:convert';
import 'dart:isolate' as vm;

import 'package:logger/logger.dart';

import '../../cast_helpers.dart';
import '../../channel.dart' show Channel;
import '../../channel.dart';
import '../../exceptions/exception_manager.dart';
import '../../exceptions/squadron_error.dart';
import '../../exceptions/squadron_exception.dart';
import '../../exceptions/worker_exception.dart';
import '../../tokens/_squadron_cancelation_token.dart';
import '../../typedefs.dart';
import '../../worker/worker_request.dart';
import '../../worker/worker_response.dart';
import '../../worker_service.dart';
import '../xplat/_pause_handler.dart';

part '_channel_impl.dart';

// Stub implementations.

/// Starts an [Isolate] using the [entryPoint] and sends a start
/// [WorkerRequest] with [startArguments]. The future completes after the
/// worker [Isolate]'s main program has provided the [SendPort] via
/// [WorkerChannel.connect].
Future<Channel> openChannel(
  EntryPoint entryPoint,
  ExceptionManager exceptionManager,
  Logger? logger,
  List startArguments, [
  PlatformThreadHook? hook,
]) async {
  final completer = Completer<Channel>();

  void failure(Object error, [StackTrace? stackTrace]) {
    if (!completer.isCompleted) {
      completer.completeError(SquadronException.from(error, stackTrace));
    }
  }

  void success(Channel channel) {
    if (!completer.isCompleted) {
      completer.complete(channel);
    }
  }

  final receiver = vm.ReceivePort();
  final exitPort = vm.ReceivePort();
  final errorPort = vm.ReceivePort();

  exitPort.listen((message) {
    failure(SquadronErrorExt.create('Connection to worker failed'));
    logger?.t('Isolate terminated.');
    receiver.close();
    errorPort.close();
    exitPort.close();
  });

  errorPort.listen((message) {
    SquadronException? error;
    try {
      final data = jsonDecode(message[0]);
      if (data is List) {
        error = exceptionManager.deserialize(data.cast<String>());
      }
    } catch (_) {
      // not a String representing a SquadronException
    }

    error ??= WorkerException(
      message[0],
      stackTrace: SquadronException.loadStackTrace(message[1]),
    );

    logger?.d(() => 'Unhandled error from Isolate: ${error?.message}.');
    failure(error);
  });

  receiver.listen((message) {
    final response = WorkerResponseExt.from(message);
    if (!response.unwrapInPlace(exceptionManager, logger)) {
      return;
    }

    final error = response.error;
    if (error != null) {
      logger?.e(() => 'Connection to Isolate failed: ${response.error}');
      failure(error);
    } else if (!completer.isCompleted) {
      logger?.t('Connected to Isolate');
      success(_VmChannel._(response.result, logger, exceptionManager));
    } else {
      logger?.e(() => 'Unexpected response: $response');
    }
  });

  final startRequest = WorkerRequest.start(receiver.sendPort, startArguments);
  startRequest.wrapInPlace();
  final isolate = await vm.Isolate.spawn(
    entryPoint,
    startRequest,
    errorsAreFatal: false,
    onExit: exitPort.sendPort,
    onError: errorPort.sendPort,
  );

  try {
    final channel = await completer.future;
    await hook?.call(isolate);
    logger?.t('Created Isolate');
    return channel;
  } catch (ex) {
    logger?.e(() => 'Connection to Isolate failed: $ex');
    isolate.kill(priority: vm.Isolate.beforeNextEvent);
    rethrow;
  }
}

/// Creates a [_VmChannel] from a [SendPort].
Channel? deserialize(PlatformChannel? channelInfo, Logger? logger,
        ExceptionManager exceptionManager) =>
    (channelInfo == null)
        ? null
        : _VmChannel._(channelInfo, logger, exceptionManager);
