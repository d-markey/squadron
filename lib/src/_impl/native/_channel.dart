import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:cancelation_token/cancelation_token.dart';
import 'package:logger/logger.dart';

import '../../channel.dart' show Channel;
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

class _BaseVmChannel {
  _BaseVmChannel._(this._sendPort, this._logger);

  final Logger? _logger;

  /// [SendPort] to communicate with the [Isolate] if the channel is owned by
  /// the worker owner. Otherwise, [SendPort] to return values to the client.
  final SendPort _sendPort;

  /// [Channel] serialization in Native world returns the [SendPort].
  PlatformChannel serialize() => _sendPort;

  void _postRequest(WorkerRequest req) {
    req.cancelToken?.ensureStarted();
    req.wrapInPlace();
    _post(_logger, req, () => _sendPort.send(req));
  }

  void _postResponse(WorkerResponse res) {
    res.wrapInPlace();
    _post(_logger, res, () => _sendPort.send(res));
  }
}

/// [Channel] implementation for the Native world.
class _VmChannel extends _BaseVmChannel implements Channel {
  _VmChannel._(super.sendPort, super.logger, this.exceptionManager) : super._();

  final ExceptionManager exceptionManager;

  bool _closed = false;

  /// [Channel] sharing in Native world returns the same instance.
  @override
  Channel share() => this;

  /// Sends a termination [WorkerRequest] to the [Isolate] and clears the
  /// [SendPort].
  @override
  FutureOr close() {
    if (!_closed) {
      _postRequest(WorkerRequest.stop());
      _closed = true;
    }
  }

  /// creates a [ReceivePort] and a [WorkerRequest] and sends it to the
  /// [Isolate]. This method expects a single value from the [Isolate]
  @override
  Future<T> sendRequest<T>(int command, List args,
      {CancelationToken? token,
      bool inspectRequest = false,
      bool inspectResponse = false}) {
    if (_closed) {
      throw SquadronErrorExt.create('Channel is closed');
    }
    final receiver = ReceivePort();
    final squadronToken = token.wrap();
    final wrapper = ValueWrapper<T>(
      WorkerRequest.userCommand(
          receiver.sendPort, command, args, squadronToken, inspectResponse),
      exceptionManager,
      _logger,
      postRequest: _postRequest,
      messages: receiver.cast(),
      token: squadronToken,
    );
    return wrapper.compute().whenComplete(receiver.close);
  }

  /// Creates a [ReceivePort] and a [WorkerRequest] and sends it to the
  /// [Isolate]. This method expects a stream of values from the [Isolate].
  /// The [Isolate] must send a [WorkerResponse.endOfStream] to close the
  /// [Stream].
  @override
  Stream<T> sendStreamingRequest<T>(int command, List args,
      {SquadronCallback onDone = Channel.noop,
      CancelationToken? token,
      bool inspectRequest = false,
      bool inspectResponse = false}) {
    if (_closed) {
      throw SquadronErrorExt.create('Channel is closed');
    }
    final receiver = ReceivePort();
    final squadronToken = token.wrap();
    final wrapper = StreamWrapper<T>(
      WorkerRequest.userCommand(
          receiver.sendPort, command, args, squadronToken, inspectResponse),
      exceptionManager,
      _logger,
      postRequest: _postRequest,
      messages: receiver.cast(),
      onDone: () {
        receiver.close();
        onDone();
      },
      token: squadronToken,
    );

    return wrapper.stream;
  }
}

/// [WorkerChannel] implementation for the native world.
class _VmWorkerChannel extends _BaseVmChannel implements WorkerChannel {
  _VmWorkerChannel._(super.sendPort, super.logger) : super._();

  /// Sends the [SendPort] to communicate with the [Isolate]. This method must
  /// be called by the worker [Isolate] upon startup.
  @override
  void connect(PlatformChannel channelInfo) => inspectAndReply(channelInfo);

  /// Sends a [WorkerResponse] with the specified data to the worker client.
  /// This method must be called from the worker [Isolate] only.
  @override
  void reply(dynamic data) => _postResponse(WorkerResponse.withResult(data));

  /// Sends a [WorkerResponse] with the specified data to the worker client.
  /// This method must be called from the worker [Isolate] only. On VM
  /// platforms, this is the same as [reply] .
  @override
  void inspectAndReply(dynamic data) => reply(data);

  @override
  void log(LogEvent message) => _postResponse(WorkerResponse.log(message));

  /// Checks if [stream] can be streamed back to the worker client. Returns
  /// `true` unless [stream] is a [ReceivePort].
  @override
  bool canStream(Stream<dynamic> stream) => stream is! ReceivePort;

  /// Sends a [WorkerResponse.closeStream] to the worker client. This method
  /// must be called from the worker [Isolate] only.
  @override
  void closeStream() => _postResponse(WorkerResponse.closeStream());

  /// Sends the [WorkerException] to the worker client. This method must be
  /// called from the worker [Isolate] only.
  @override
  void error(SquadronException error) {
    _logger?.t(() => 'replying with error: ${error.runtimeType} $error');
    _postResponse(WorkerResponse.withError(error));
  }
}

// Stub implementations.

/// Starts an [Isolate] using the [entryPoint] and sends a start
/// [WorkerRequest] with [startArguments]. The future completes after the
/// worker [Isolate]'s main program has provided the [SendPort] via
/// [_VmWorkerChannel.connect].
Future<Channel> openChannel(EntryPoint entryPoint,
    ExceptionManager exceptionManager, Logger? logger, List startArguments,
    [PlatformThreadHook? hook]) async {
  final completer = Completer<Channel>();
  final receiver = ReceivePort();

  final startRequest = WorkerRequest.start(receiver.sendPort, startArguments);

  late final Isolate isolate;
  final exitPort = ReceivePort();
  final errorPort = ReceivePort();

  exitPort.listen((message) {
    logger?.t('Isolate terminated.');
    receiver.close();
    exitPort.close();
    errorPort.close();
  });

  errorPort.listen((message) {
    SquadronException? error;
    try {
      final data = jsonDecode(message[0]);
      if (data is List) {
        error = exceptionManager.deserialize(data.cast<String>());
      }
    } catch (ex) {
      // not a String representing a SquadronException
    }

    error ??= WorkerException(message[0],
        stackTrace: SquadronException.loadStackTrace(message[1]));
    logger?.d(() => 'unhandled error from Isolate: ${error?.message}.');
    if (!completer.isCompleted) {
      completer.completeError(error, error.stackTrace);
    }
  });

  receiver.listen((message) {
    final response = WorkerResponseExt.from(message);
    if (!response.unwrapInPlace(exceptionManager, logger)) {
      return;
    }

    if (!completer.isCompleted) {
      final error = response.error;
      if (error != null) {
        logger?.e(() => 'connection to Isolate failed: ${response.error}');
        completer.completeError(error, error.stackTrace);
        isolate.kill(priority: Isolate.immediate);
      } else {
        logger?.t('connected to Isolate');
        final channel = _VmChannel._(response.result, logger, exceptionManager);
        completer.complete(channel);
      }
    } else {
      logger?.e(() => 'unexpected response: $response');
    }
  });

  startRequest.wrapInPlace();
  isolate = await Isolate.spawn(
    entryPoint,
    startRequest,
    errorsAreFatal: false,
    onExit: exitPort.sendPort,
    onError: errorPort.sendPort,
  );

  final channel = await completer.future;

  if (hook != null) {
    final hookRes = UserCode.run(
      logger,
      () => hook(isolate),
      'PlatforWorkerHook for $entryPoint',
    );
    if (hookRes is Future) {
      await hookRes;
    }
  }

  logger?.t('created Isolate');

  return channel;
}

/// Creates a [_VmChannel] from a [SendPort].
Channel? deserializeChannel(PlatformChannel? channelInfo, Logger? logger,
        ExceptionManager exceptionManager) =>
    (channelInfo == null)
        ? null
        : _VmChannel._(channelInfo, logger, exceptionManager);

/// Creates a [_VmWorkerChannel] from a [SendPort].
WorkerChannel? deserializeWorkerChannel(
        PlatformChannel? channelInfo, Logger? logger) =>
    (channelInfo == null) ? null : _VmWorkerChannel._(channelInfo, logger);
