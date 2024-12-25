import 'dart:async';
import 'dart:js_interop';

import 'package:logger/web.dart';
import 'package:meta/meta.dart';
import 'package:web/web.dart' as web;

import '../../exceptions/squadron_error.dart';
import '../../exceptions/squadron_exception.dart';
import '../../typedefs.dart';
import '../../worker/worker_channel.dart';
import '../../worker/worker_response.dart';
import '../xplat/_transferables.dart';
import '_typedefs.dart' as impl;

/// [WorkerChannel] implementation for the JavaScript world.
final class _WebWorkerChannel implements WorkerChannel {
  _WebWorkerChannel._(this._sendPort, this._logger);

  /// [web.MessagePort] to communicate with the [web.Worker] if the channel is
  /// owned by the worker owner. Otherwise, [web.MessagePort] to return values
  /// to the client.
  final web.MessagePort _sendPort;

  final Logger? _logger;

  void _postResponse(WorkerResponse res) {
    try {
      _sendPort.postMessage(res.wrapInPlace().jsify());
    } catch (ex, st) {
      _logger?.e(() => 'Failed to post response $res: $ex');
      throw SquadronErrorExt.create('Failed to post response: $ex', st);
    }
  }

  void _inspectAndPostResponse(WorkerResponse res) {
    try {
      final data = res.wrapInPlace();
      final transfer = Transferables.get(data);
      if (transfer == null || transfer.isEmpty) {
        _sendPort.postMessage(data.jsify());
      } else {
        _sendPort.postMessage(data.jsify(), transfer.jsify() as JSArray);
      }
    } catch (ex, st) {
      _logger?.e(() => 'Failed to post response $res: $ex');
      throw SquadronErrorExt.create('Failed to post response: $ex', st);
    }
  }

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
  void error(Object err, [StackTrace? stackTrace, int? command]) {
    final ex = SquadronException.from(err, stackTrace, command);
    _postResponse(WorkerResponse.withError(ex));
  }
}

/// Creates a [WorkerChannel] from a [web.MessagePort].
@internal
WorkerChannel? deserialize(PlatformChannel? channelInfo, [Logger? logger]) =>
    (channelInfo == null)
        ? null
        : _WebWorkerChannel._(channelInfo as impl.PlatformChannel, logger);
