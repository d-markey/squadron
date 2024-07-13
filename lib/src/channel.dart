import 'dart:async';

import 'package:logger/logger.dart';

import '_impl/xplat/_channel.dart'
    if (dart.library.io) '_impl/native/_channel.dart'
    if (dart.library.html) '_impl/web/_channel.dart'
    if (dart.library.js_interop) '_impl/web/_channel.dart' as impl;
import 'exceptions/exception_manager.dart';
import 'tokens/_squadron_cancelation_token.dart';
import 'typedefs.dart';
import 'worker/worker_request.dart';
import 'worker/worker_response.dart';
import 'worker_service.dart';

/// A [Channel] supports communication from a client to a platform worker. It
/// is used to send a [WorkerRequest] to a platform worker.
abstract class Channel {
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

  /// Static method that does nothing. Useful when a [SquadronCallback] is
  /// required but there is nothing to do.
  static void noop() {}

  /// Creates a [WorkerRequest] and sends it to the worker. This method expects
  /// a single value from the worker.
  Future<T> sendRequest<T>(int command, List args,
      {SquadronCancelationToken? token,
      bool inspectRequest = false,
      bool inspectResponse = false});

  /// Creates a [WorkerRequest] and sends it to the worker. This method expects
  /// a stream of values from the worker. The worker must send a
  /// [WorkerResponse.closeStream] message to close the [Stream].
  Stream<T> sendStreamingRequest<T>(int command, List args,
      {SquadronCallback onDone = Channel.noop,
      SquadronCancelationToken? token,
      bool inspectRequest = false,
      bool inspectResponse = false});

  /// Starts a worker using the [entryPoint] and sends a start [WorkerRequest]
  /// with [startArguments]. The future must not complete before the worker is
  /// ready to serve requests.
  static Future<Channel> open(ExceptionManager exceptionManager, Logger? logger,
          EntryPoint entryPoint, List startArguments,
          [PlatformThreadHook? hook]) =>
      impl.openChannel(
          entryPoint, exceptionManager, logger, startArguments, hook);

  /// Deserializes a [Channel] from an opaque [channelInfo].
  static Channel? deserialize(PlatformChannel? channelInfo, Logger? logger,
          [ExceptionManager? exceptionManager]) =>
      impl.deserializeChannel(
          channelInfo, logger, exceptionManager ?? ExceptionManager());
}
