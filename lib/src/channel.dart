import 'dart:async';

import 'package:logger/web.dart';
import 'package:meta/meta.dart';

import '_impl/xplat/_channel.dart'
    if (dart.library.io) '_impl/native/_channel.dart'
    if (dart.library.html) '_impl/web/_channel.dart'
    if (dart.library.js) '_impl/web/_channel.dart'
    if (dart.library.js_interop) '_impl/web/_channel.dart' as impl;
import 'exceptions/exception_manager.dart';
import 'exceptions/task_terminated_exception.dart';
import 'tokens/_squadron_cancelation_token.dart';
import 'typedefs.dart';
import 'worker/worker_request.dart';
import 'worker/worker_response.dart';

/// A [Channel] supports communication from a client to a platform worker. It
/// is used to send a [WorkerRequest] to a platform worker.
abstract interface class Channel {
  /// The [ExceptionManager] attached to this channel.
  ExceptionManager get exceptionManager;

  /// The [Logger] attached to this channel.
  Logger? get logger;

  /// [Channel] serialization. Returns an opaque object that can be transfered
  /// from the client to the worker.
  PlatformChannel serialize();

  /// [Channel] sharing. Returns a [Channel] object that can be provided to
  /// enable another worker to call the channel's worker.
  Channel share();

  /// Sends a termination [WorkerRequest] to the worker. The [Channel] should
  /// release any resource related to the worker and should not be used after
  /// this method has been called.
  FutureOr<void> close();

  /// Sends a close stream [WorkerRequest] to the worker.
  FutureOr<void> cancelStream(int streamId);

  /// Sends a cancel token [WorkerRequest] to the worker.
  FutureOr<void> cancelToken(SquadronCancelationToken? token);

  /// Creates a [WorkerRequest] and sends it to the worker. This method expects
  /// a single value from the worker.
  Future<dynamic> sendRequest(int command, List args,
      {SquadronCancelationToken? token,
      bool inspectRequest = false,
      bool inspectResponse = false});

  /// Creates a [WorkerRequest] and sends it to the worker. This method expects
  /// a stream of values from the worker. The worker must send a
  /// [WorkerResponse.closeStream] message to close the [Stream].
  Stream<dynamic> sendStreamingRequest(int command, List args,
      {SquadronCancelationToken? token,
      bool inspectRequest = false,
      bool inspectResponse = false});

  /// Starts a worker using the [entryPoint] and sends a start [WorkerRequest]
  /// with [startArguments]. The future must not complete before the worker is
  /// ready to serve requests.
  static Future<Channel> open(
    ExceptionManager exceptionManager,
    Logger? logger,
    EntryPoint entryPoint,
    List startArguments,
    PlatformThreadHook? hook,
  ) =>
      impl.openChannel(
          entryPoint, exceptionManager, logger, startArguments, hook);

  /// Deserializes a [Channel] from an opaque [channelInfo].
  static Channel? deserialize(
    PlatformChannel? channelInfo, [
    Logger? logger,
    ExceptionManager? exceptionManager,
  ]) =>
      impl.deserialize(channelInfo, logger, exceptionManager);
}

@internal
extension ChannelImpl on Channel {
  void terminate(TaskTerminatedException ex) => impl.terminateChannel(this, ex);

  int get activeConnections => impl.getActiveConnections(this);
}
