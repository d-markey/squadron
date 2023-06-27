import 'dart:async';

import 'package:meta/meta.dart';

import 'cancellation_token.dart';

import 'xplat/_cancellation_token_ref.dart';
import 'xplat/_channel.dart'
    if (dart.library.io) 'native/_channel.dart'
    if (dart.library.js) 'browser/_channel.dart'
    if (dart.library.html) 'browser/_channel.dart';

import 'squadron_exception.dart';
import 'worker.dart';
import 'worker_request.dart';
import 'worker_response.dart';
import 'worker_service.dart';
import 'xplat/_worker_monitor.dart';

typedef PostRequest = void Function(WorkerRequest req);

/// A [Channel] supports communication from a client to a platform worker. It is used to send a [WorkerRequest] to
/// a platform worker.
abstract class Channel {
  /// The ID of the worker attached to this [Channel].
  String get workerId;

  /// [Channel] serialization. Returns an opaque object that can be transfered from the client to the worker.
  dynamic serialize();

  /// [Channel] sharing. Returns a [Channel] object that can be provided to enable another worker to call the
  /// channel's worker.
  Channel share();

  /// Sends a termination [WorkerRequest] to the worker. The [Channel] should release any resource related to the
  /// worker and should not be used after this method has been called.
  FutureOr close();

  /// Static method that does nothing. Useful when a [SquadronCallback] is required but there is nothing to do.
  static void noop() {}

  /// Creates a [WorkerRequest] and sends it to the worker. This method expects a single value from the worker.
  Future<T> sendRequest<T>(int command, List args,
      {CancellationToken? token,
      bool inspectRequest = false,
      bool inspectResponse = false});

  /// Creates a [WorkerRequest] and sends it to the worker. This method expects a stream of values from the worker.
  /// The worker must send a [WorkerResponse.closeStream] message to close the [Stream].
  Stream<T> sendStreamingRequest<T>(int command, List args,
      {SquadronCallback onDone = Channel.noop,
      CancellationToken? token,
      bool inspectRequest = false,
      bool inspectResponse = false});

  /// Starts a worker using the [entryPoint] and sends a start [WorkerRequest] with [startArguments]. The future
  /// must not complete before the worker is ready to serve requests.
  static Future<Channel> open(
          EntryPoint entryPoint, String workerId, List startArguments,
          [PlatformWorkerHook? hook]) =>
      openChannel(entryPoint, workerId, startArguments, hook);

  /// Deserializes a [Channel] from an opaque [channelInfo].
  static Channel? deserialize(dynamic channelInfo) =>
      deserializeChannel(channelInfo);
}

/// A [WorkerChannel] supports communication from a platform worker to the client that posted the [WorkerRequest].
/// It is used to send [WorkerResponse] back to the client.
abstract class WorkerChannel {
  /// [WorkerChannel] serialization. Returns an opaque object that can be transfered from the client to the worker.
  dynamic serialize();

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
  static WorkerChannel? deserialize(dynamic channelInfo) =>
      deserializeWorkerChannel(channelInfo);
}

@internal
extension PipeExtension on WorkerChannel {
  /// Forwards stream events to client.
  Future<void> pipe(Stream stream, void Function(dynamic) reply,
      WorkerMonitor monitor, CancellationTokenReference tokenRef) {
    StreamSubscription? subscription;
    final done = Completer();

    // stream canceller
    void onDone() {
      closeStream();
      subscription?.cancel();
      done.complete();
    }

    // register stream canceller callback and connect stream with client
    final streamId = monitor.registerStreamCanceller(tokenRef, onDone);
    reply(streamId);

    // start forwarding messages to the client
    subscription = stream.listen(reply,
        onError: _err, onDone: onDone, cancelOnError: false);

    return done.future.whenComplete(() {
      // unregister stream canceller callback
      monitor.unregisterStreamCanceller(tokenRef, streamId);
    });
  }

  void _err(Object ex, StackTrace st) => error(SquadronException.from(ex, st));
}
