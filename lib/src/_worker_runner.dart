import 'dart:async';

import '_worker_monitor.dart';
import 'channel.dart';
import 'squadron.dart';
import 'squadron_error.dart';
import 'squadron_exception.dart';
import 'worker.dart';
import 'worker_exception.dart';
import 'worker_request.dart';
import 'worker_service.dart';

class WorkerRunner {
  WorkerRunner(this._monitor);

  factory WorkerRunner.use(WorkerService service) {
    final worker = WorkerRunner(WorkerMonitor(Channel.noop));
    worker._operations.addAll(service.operations);
    return worker;
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
      return _monitor.terminate();
    } else if (request.cancel) {
      return _monitor.cancel(request.cancelToken!);
    } else if (request.cancelStream) {
      return _monitor.cancelStream(request.streamId!);
    } else if (client == null) {
      throw newSquadronError('missing client for request: $request');
    }

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
        // stream values to the client
        late final StreamSubscription subscription;
        late final int streamId;
        final done = Completer();

        void shutdown() {
          client.closeStream();
          subscription.cancel();
          done.complete();
        }

        subscription = result.listen(
          (data) => client.reply(data),
          onError: (ex, st) =>
              client.error(SquadronException.from(error: ex, stackTrace: st)),
          onDone: shutdown,
          cancelOnError: false,
        );

        streamId = _monitor.registerStreamCanceller(shutdown);
        tokenRef.registerStreamCanceller(shutdown);
        client.connectStream(streamId);

        await done.future.whenComplete(() {
          _monitor.unregisterStreamCanceller(streamId);
          tokenRef.unregisterStreamCanceller(shutdown);
        });
      } else {
        // send result to client
        client.reply(result);
      }
    } catch (e, st) {
      client.error(SquadronException.from(error: e, stackTrace: st));
    } finally {
      _monitor.done(tokenRef);
    }
  }
}
