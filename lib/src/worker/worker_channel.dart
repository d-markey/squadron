import 'dart:async';

import 'package:meta/meta.dart';

import '../_impl/xplat/_channel.dart'
    if (dart.library.io) '../_impl/native/_channel.dart'
    if (dart.library.js) '../_impl/browser/_channel.dart'
    if (dart.library.html) '../_impl/browser/_channel.dart';
import '../_impl/xplat/_worker_monitor.dart';
import '../exceptions/squadron_exception.dart';
import 'worker_request.dart';

typedef PostRequest = void Function(WorkerRequest req);

/// A [WorkerChannel] supports communication from a platform worker to the client that posted the [WorkerRequest].
/// It is used to send [WorkerResponse] back to the client.
abstract class WorkerChannel {
  /// [WorkerChannel] serialization. Returns an opaque object that can be transfered from the client to the worker.
  PlatformChannel serialize();

  /// Connects the [Channel] with the Squadron [Worker]. [channelInfo] is an opaque object than can be deserialized
  /// as a [Channel]. This method must be called by the worker upon startup.
  void connect(Object channelInfo);

  /// Sends a [WorkerResponse] with the specified data to the worker client. This method must be called from the
  /// worker only. On Web patforms, this version does not check arguments for transferable objects.
  void reply(dynamic data);

  /// Sends a [WorkerResponse] with the specified data to the worker client. This method must be called from the
  /// worker only. On Web patforms, this version must check arguments for transferable objects.
  void inspectAndReply(dynamic data);

  /// Sends a [WorkerResponse.log] with the specified data to the worker client. This method must be called from the
  /// worker only.
  void log(String message);

  /// Checks if [stream] can be streamed back to the worker client.
  bool canStream(Stream stream);

  /// Sends a [WorkerResponse.closeStream] to the worker client. This method must be called from the worker only.
  void closeStream();

  /// Sends a [WorkerResponse] with the specified error to the worker client. This method must be called from the
  /// worker only.
  void error(SquadronException error);

  /// Deserializes a [Channel] from an opaque [channelInfo].
  static WorkerChannel? deserialize(PlatformChannel? channelInfo) =>
      deserializeWorkerChannel(channelInfo);
}

@internal
extension WorkerChannelExt on WorkerChannel {
  /// Forwards stream events to client.
  Future<void> pipe(
      Stream stream, void Function(dynamic) reply, WorkerMonitor monitor) {
    StreamSubscription? subscription;
    final done = Completer();

    // stream canceler
    void onDone() {
      closeStream();
      subscription?.cancel();
      done.complete();
    }

    // register stream canceler callback and connect stream with client
    final streamId = monitor.registerStreamCanceler(onDone);
    reply(streamId);

    // start forwarding messages to the client
    subscription = stream.listen(reply,
        onError: _err, onDone: onDone, cancelOnError: false);

    return done.future.whenComplete(() {
      // unregister stream canceler callback
      monitor.unregisterStreamCanceler(streamId);
    });
  }

  void _err(Object ex, StackTrace st) => error(SquadronException.from(ex, st));
}
