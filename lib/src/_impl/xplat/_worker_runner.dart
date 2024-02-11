import 'dart:async';

import '../../channel.dart';
import '../../exceptions/squadron_error.dart';
import '../../exceptions/squadron_exception.dart';
import '../../exceptions/worker_exception.dart';
import '../../local_worker/local_worker.dart';
import '../../squadron.dart';
import '../../worker/worker.dart';
import '../../worker/worker_channel.dart';
import '../../worker/worker_message.dart';
import '../../worker/worker_request.dart';
import '../../worker_service.dart';
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
  Future connect(List? startRequest, Object channelInfo,
      WorkerInitializer initializer) async {
    startRequest?.unwrapRequestInPlace();
    final client = startRequest?.client;

    if (startRequest == null) {
      throw SquadronErrorExt.create(
          'connection request expected', StackTrace.current);
    } else if (client == null) {
      throw SquadronErrorExt.create(
          'missing client for connection request', StackTrace.current);
    }

    try {
      if (!startRequest.isConnection) {
        throw SquadronErrorExt.create(
            'connection request expected', StackTrace.current);
      } else if (_operations.isNotEmpty) {
        throw SquadronErrorExt.create('already connected', StackTrace.current);
      }

      Squadron.setId(startRequest.id!);
      Squadron.setParent(client);
      Squadron.logLevel = startRequest.logLevel!;
      Squadron.debugMode = (startRequest.travelTime != null);

      WorkerService service;
      final init = initializer(startRequest);
      if (init is Future) {
        service = await init;
      } else {
        service = init;
      }

      final operations = service.operations;
      if (operations.keys.where((k) => k <= 0).isNotEmpty) {
        throw SquadronErrorExt.create(
            'invalid command identifier in service operations map; command ids must be > 0',
            StackTrace.current);
      }
      _operations.addAll(operations);

      final install = _monitor.install(service);
      if (install is Future) {
        await install;
      }

      client.connect(channelInfo);
    } catch (ex, st) {
      client.error(SquadronException.from(ex, st));
    }
  }

  /// [WorkerRequest] handler dispatching commands according to the [_operations] map.
  void processMessage(List request) async {
    request.unwrapRequestInPlace();
    final client = request.client;

    if (request.isTermination) {
      // terminate the worker
      return _monitor.terminate();
    } else if (request.isTokenCancelation) {
      // cancel a token
      return _monitor.updateToken(request.cancelToken!);
    } else if (request.isStreamCancelation) {
      // cancel a stream
      return _monitor.cancelStream(request.streamId!);
    } else if (client == null) {
      throw SquadronErrorExt.create(
          'missing client for request: $request', StackTrace.current);
    }

    // start monitoring execution
    final tokenRef = _monitor.begin(request);
    try {
      if (request.isConnection) {
        // connection request must be handled beforehand
        throw SquadronErrorExt.create(
            'unexpected connection request: $request', StackTrace.current);
      } else if (_operations.isEmpty) {
        // commands are not available yet (maybe connect() wasn't called or awaited)
        throw WorkerException('worker service is not ready');
      }

      // find the operation matching the request command
      final op = _operations[request.command];
      if (op == null) {
        throw WorkerException('unknown command: ${request.command}');
      }
      // process
      dynamic result = op(request);
      if (result is Future) {
        result = await result;
      }

      // send results back with the proper reply method
      final reply = request.reply!;
      if (result is Stream && client.canStream(result)) {
        // result is a stream: forward data to the client
        await client.pipe(result, reply, _monitor);
      } else {
        // result is a value: send to the client
        reply(result);
      }
    } catch (e, st) {
      // error: send to client
      client.error(SquadronException.from(e, st));
    } finally {
      // stop monitoring execution
      _monitor.done(tokenRef);
    }
  }
}
