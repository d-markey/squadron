import 'dart:async';

import 'package:logger/logger.dart';

import '../_impl/xplat/_channel.dart'
    if (dart.library.io) '../_impl/native/_channel.dart'
    if (dart.library.js) '../_impl/browser/_channel.dart'
    if (dart.library.html) '../_impl/browser/_channel.dart';
import '../exceptions/squadron_exception.dart';
import '../typedefs.dart';
import 'worker_request.dart';

typedef PostRequest = void Function(WorkerRequest req);

/// A [WorkerChannel] supports communication from a platform worker to the
/// client that posted the [WorkerRequest]. It is used to send [WorkerResponse]
/// back to the client.
abstract class WorkerChannel {
  /// [WorkerChannel] serialization. Returns an opaque object that can be
  /// transfered from the client to the worker.
  PlatformChannel serialize();

  /// Connects the [Channel] with the Squadron [Worker]. [channelInfo] is an
  /// opaque object than can be deserialized as a [Channel]. This method must
  /// be called by the worker upon startup.
  void connect(PlatformChannel channelInfo);

  /// Sends a [WorkerResponse] with the specified data to the worker client.
  /// This method must be called from the worker only. On Web patforms, this
  /// version does not check arguments for transferable objects.
  void reply(dynamic data);

  /// Sends a [WorkerResponse] with the specified data to the worker client.
  /// This method must be called from the worker only. On Web patforms, this
  /// version must check arguments for transferable objects.
  void inspectAndReply(dynamic data);

  /// Sends a [WorkerResponse.log] with the specified data to the worker
  /// client. This method must be called from the worker only.
  void log(LogEvent message);

  /// Checks if [stream] can be streamed back to the worker client.
  bool canStream(Stream stream);

  /// Sends a [WorkerResponse.closeStream] to the worker client. This method
  /// must be called from the worker only.
  void closeStream();

  /// Sends a [WorkerResponse] with the specified error to the worker client.
  /// This method must be called from the worker only.
  void error(SquadronException error);

  /// Deserializes a [Channel] from an opaque [channelInfo].
  static WorkerChannel? deserialize(
          PlatformChannel? channelInfo, Logger? logger) =>
      deserializeWorkerChannel(channelInfo, logger);
}
