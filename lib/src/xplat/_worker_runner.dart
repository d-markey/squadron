import 'dart:async';

import '../local_worker.dart';
import '../channel.dart';
import '../squadron.dart';
import '../squadron_error.dart';
import '../squadron_exception.dart';
import '../worker.dart';
import '../worker_exception.dart';
import '../worker_request.dart';
import '../worker_service.dart';

import '_worker_monitor.dart';

class WorkerRunner {
  /// Constructs a new worker runner monitored by [monitor].
  WorkerRunner(WorkerMonitor monitor) : _monitor = monitor;

  /// Constructs a new worker runner for a [localWorker].
  factory WorkerRunner.use(LocalWorker localWorker) {
    final runner = WorkerRunner(WorkerMonitor(Channel.noop));
    runner._operations.addAll(localWorker.service.operations);
    return runner;
  }

  final _operations = <int, CommandHandler>{};
  final WorkerMonitor _monitor;

  /// Called by the platform worker upon startup, in response to a start [WorkerRequest]. [channelInfo] is an opaque
  /// object sent back from the platform worker to the Squadron [Worker] and used to communicate with the platform
  /// worker. Typically, [channelInfo] would be a [SendPort] (native) or a [MessagePort] (browser). [initializer]
  /// is called to build the [WorkerService] associated to the worker. The runner's [_operations] map will be
  /// populated with operations from the service.
  Future connect(
      Map? message, Object channelInfo, WorkerInitializer initializer) async {
    final startRequest = WorkerRequest.deserialize(message);
    final client = startRequest?.client;

    if (startRequest == null) {
      throw newSquadronError('connection request expected');
    } else if (client == null) {
      throw newSquadronError('missing client for connection request');
    }

    try {
      if (!startRequest.connect) {
        throw newSquadronError('connection request expected');
      } else if (_operations.isNotEmpty) {
        throw newSquadronError('already connected');
      }

      Squadron.setId(startRequest.id!);
      Squadron.logLevel = startRequest.logLevel!;

      final init = initializer(startRequest);
      final operations = ((init is Future) ? await init : init).operations;
      if (operations.keys.where((k) => k <= 0).isNotEmpty) {
        throw newSquadronError(
            'invalid command identifier in service operations map; command ids must be > 0');
      }
      _operations.addAll(operations);
      client.connect(channelInfo);
    } catch (e, st) {
      client.error(SquadronException.from(error: e, stackTrace: st));
    }
  }

  /// [WorkerRequest] handler dispatching commands aoocrding to the [_operations] map.
  void processMessage(Map message) async {
    Squadron.finest(() => 'processing request $message');
    final request = WorkerRequest.deserialize(message);
    final client = request?.client;

    if (request == null) {
      throw newSquadronError('invalid message');
    } else if (request.terminate) {
      // terminate the worker
      return _monitor.terminate();
    } else if (request.cancel) {
      // cancel a token
      return _monitor.cancelToken(request.cancelToken!);
    } else if (request.cancelStream) {
      // cancel a stream
      return _monitor.cancelStream(request.streamId!);
    } else if (client == null) {
      throw newSquadronError('missing client for request: $request');
    }

    // start monitoring execution
    final tokenRef = _monitor.begin(request);
    try {
      if (request.connect) {
        // connection request must be handled beforehand
        throw newSquadronError('unexpected connection request: $message');
      } else if (_operations.isEmpty) {
        // commands are not available yet (maybe connect() wasn't called or awaited)
        throw WorkerException('worker service is not ready');
      }
      // retrieve operation matching the request command
      final op = _operations[request.command];
      if (op == null) {
        throw WorkerException('unknown command: ${request.command}');
      }
      // process
      dynamic result = op(request);
      if (result is Future) {
        result = await result;
      }
      if (result is Stream && client.canStream(result)) {
        // result is a stream: forward data to the client
        late final StreamSubscription subscription;
        final done = Completer();

        // stream canceller
        void shutdown() {
          client.closeStream();
          subscription.cancel();
          done.complete();
        }

        // register stream canceller callback and connect stream with client
        final streamId = _monitor.registerStreamCanceller(tokenRef, shutdown);
        client.connectStream(streamId);

        // start forwarding messages to the client
        subscription = result.listen(
          (data) => client.reply(data),
          onError: (ex, st) =>
              client.error(SquadronException.from(error: ex, stackTrace: st)),
          onDone: shutdown,
          cancelOnError: false,
        );

        await done.future.whenComplete(() {
          // unregister stream canceller callback
          _monitor.unregisterStreamCanceller(tokenRef, streamId);
        });
      } else {
        // result is a value: send to the client
        client.reply(result);
      }
    } catch (e, st) {
      client.error(SquadronException.from(error: e, stackTrace: st));
    } finally {
      // stop monitoring execution
      _monitor.done(tokenRef);
    }
  }
}
