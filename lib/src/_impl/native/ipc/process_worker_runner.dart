import 'dart:async';
import 'dart:io';

import 'package:logger/web.dart';

import '../../../exceptions/squadron_error.dart';
import '../../../exceptions/squadron_exception.dart';
import '../../../transport/channel_multiplexer.dart';
import '../../../transport/stream_transport.dart';
import '../../../typedefs.dart';
import '../../../worker/worker_channel.dart';
import '../../../worker/worker_request.dart';
import '../../../worker/worker_response.dart';
import '../../xplat/_worker_runner.dart' as xplat;

class IpcWorkerChannel implements WorkerChannel {
  IpcWorkerChannel(this._multiplexer, this._channelId);

  final ChannelMultiplexer _multiplexer;
  final int _channelId;

  @override
  Future<void> connect(PlatformChannel channelInfo) async {
    await reply(true);
  }

  @override
  Future<void> reply(dynamic data) async {
    await _multiplexer.send(_channelId, MessageType.response,
        payload: WorkerResponse.withResult(data));
  }

  @override
  void inspectAndReply(dynamic data) => reply(data);

  @override
  void log(LogEvent message) {
    _multiplexer.send(_channelId, MessageType.controlSignal,
        controlSignal: ControlSignal.log, payload: message);
  }

  @override
  bool canStream(Stream<dynamic> stream) => true;

  @override
  void closeStream() {
    _multiplexer.send(_channelId, MessageType.controlSignal,
        controlSignal: ControlSignal.endOfStream);
  }

  @override
  void error(Object err, [StackTrace? stackTrace, int? command]) {
    final ex = SquadronException.from(err, stackTrace, command);
    _multiplexer.send(_channelId, MessageType.controlSignal,
        controlSignal: ControlSignal.error, payload: ex.serialize());
  }
}

void runWorkerProcess(WorkerInitializer initializer) async {
  try {
    stdin.lineMode = false;
    stdin.echoMode = false;
  } catch (_) {}

  final transport = StreamTransport(input: stdin, output: stdout);
  final multiplexer = ChannelMultiplexer(transport);

  xplat.WorkerRunner? runner;

  multiplexer.messages.listen((msg) async {
    try {
      if (msg.type == MessageType.request) {
        final req = msg.payload is WorkerRequest
            ? msg.payload as WorkerRequest
            : WorkerRequest.from(msg.payload);

        final workerChannel = IpcWorkerChannel(multiplexer, msg.channelId);
        req.data[1] = workerChannel;

        if (req.isConnection) {
          runner = xplat.WorkerRunner((r) {});
          try {
            await runner!.connect(req, workerChannel, initializer);
          } catch (e, st) {
            workerChannel.error(e, st);
          }
        } else if (runner != null) {
          runner!.processRequest(req);
        } else {
          workerChannel.error(
              SquadronErrorImpl.create('Process worker is not connected'));
        }
      } else if (msg.type == MessageType.controlSignal &&
          msg.controlSignal == ControlSignal.cancellation) {
        // Handle cancellation
      }
    } catch (ex, st) {
      final workerChannel = IpcWorkerChannel(multiplexer, msg.channelId);
      workerChannel.error(ex, st);
    }
  });
}
