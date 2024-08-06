import 'dart:async';

import 'package:logger/logger.dart';

import '../_impl/xplat/_worker_channel.dart'
    if (dart.library.io) '../_impl/native/_worker_channel.dart'
    if (dart.library.html) '../_impl/web/_worker_channel.dart'
    if (dart.library.js_interop) '../_impl/web/_worker_channel.dart' as impl;
import '../channel.dart';
import '../typedefs.dart';
import 'worker.dart';
import 'worker_request.dart';
import 'worker_response.dart';

typedef PostRequest = void Function(WorkerRequest req);

/// A [WorkerChannel] supports communication from a platform worker to the
/// client that posted the [WorkerRequest]. It is used to send [WorkerResponse]
/// back to the client.
abstract class WorkerChannel {
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
  /// version checks arguments for transferable objects.
  void inspectAndReply(dynamic data);

  /// Sends a [WorkerResponse.log] with the specified data to the worker
  /// client.
  void log(LogEvent message);

  /// Checks if [stream] can be streamed back to the worker client.
  bool canStream(Stream<dynamic> stream);

  /// Sends a [WorkerResponse.closeStream] to the worker client.
  void closeStream();

  /// Sends a [WorkerResponse] with the specified error to the worker client.
  void error(Object err, [StackTrace? stacktrace, int? command]);

  /// Deserializes a [Channel] from an opaque [channelInfo].
  static WorkerChannel? deserialize(
          PlatformChannel? channelInfo, Logger? logger) =>
      impl.deserialize(channelInfo, logger);
}
