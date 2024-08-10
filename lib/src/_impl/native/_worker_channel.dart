import 'dart:async';
import 'dart:isolate';

import 'package:logger/logger.dart';
import 'package:meta/meta.dart';

import '../../exceptions/squadron_error.dart';
import '../../exceptions/squadron_exception.dart';
import '../../exceptions/worker_exception.dart';
import '../../typedefs.dart';
import '../../worker/worker_channel.dart';
import '../../worker/worker_response.dart';

/// [WorkerChannel] implementation for the native world.
class _VmWorkerChannel implements WorkerChannel {
  _VmWorkerChannel._(this._sendPort, this._logger);

  final Logger? _logger;

  /// [SendPort] to communicate with the [Isolate] if the channel is owned by
  /// the worker owner. Otherwise, [SendPort] to return values to the client.
  final SendPort _sendPort;

  void _postResponse(WorkerResponse res) {
    try {
      final data = res.wrapInPlace();
      _sendPort.send(data);
    } catch (ex, st) {
      _logger?.e(() => 'Failed to post response $res: $ex');
      throw SquadronErrorExt.create('Failed to post response: $ex', st);
    }
  }

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
  void error(Object err, [StackTrace? stackTrace, int? command]) {
    final ex = SquadronException.from(err, stackTrace, command);
    _postResponse(WorkerResponse.withError(ex));
  }
}

/// Creates a [WorkerChannel] from a [SendPort].
@internal
WorkerChannel? deserialize(PlatformChannel? channelInfo, Logger? logger) =>
    (channelInfo == null) ? null : _VmWorkerChannel._(channelInfo, logger);
