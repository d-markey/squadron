import 'dart:async';

import 'worker_exception.dart';
import 'worker_monitor.dart';
import 'worker_request.dart';
import 'worker_response.dart';

typedef WorkerInitializer = FutureOr<WorkerService> Function(
    WorkerRequest startRequest);

typedef CommandHandler = FutureOr Function(WorkerRequest req);

// void _noop() {}

/// Base class for a worker service.
abstract class WorkerService {
  /// Map of command handlers. Upon reception of a [WorkerRequest], the platform worker will dispatch the request
  /// to the [CommandHandler] mathing the value of [WorkerRequest.command].
  Map<int, CommandHandler> get operations;

  /// Called by the platform worker upon startup, in response to a start [WorkerRequest].
  /// [channelInfo] is an opaque object sent back from the platform worker to the Squadron [Worker]
  /// and used to communicate with the platform worker. Typically, [channelInfo] would be a [SendPort]
  /// (native) or a [MessagePort] (browser). [operations] is an optional map of command ids to command
  /// methods which will be initialized with operations exposed by the [service]. If [operations] is
  /// empty, it should mean that [connect] has not been called.
  static Future connect(
      Map? message,
      Object channelInfo,
      Map<int, CommandHandler>? operations,
      WorkerInitializer? initializer) async {
    final startRequest = WorkerRequest.deserialize(message);
    final client = startRequest.client;
    if (client == null) {
      print('Missing client for connection request');
      return;
    }
    try {
      if (operations?.isNotEmpty ?? false) {
        client.reply(
            WorkerResponse.withError(WorkerException('Already connected')));
        return;
      }
      if (operations != null && initializer != null) {
        final init = initializer(startRequest);
        final service = (init is Future) ? await init : init;
        operations.addAll(service.operations);
      }
      client.connect(channelInfo);
    } on WorkerException catch (e) {
      client.reply(WorkerResponse.withError(e));
    } catch (e, st) {
      client.reply(WorkerResponse.withError(e, st.toString()));
    }
  }

  /// Generic [WorkerRequest] handler based on a map of command ids/command methods.
  /// [operations] contains a map of command handlers indexed by command ID.
  static void process(Map<int, CommandHandler> operations, Map message,
      WorkerMonitor monitor) async {
    final request = WorkerRequest.deserialize(message);
    if (request.terminate) {
      monitor.terminate();
      return;
    }

    if (request.cancel) {
      monitor.cancel(
          request.cancelToken!, request.args.isEmpty ? null : request.args[0]);
      return;
    }

    // start request must be handled beforehand
    if (request.connect) {
      final msg = 'Unhandled start or termination request: $request';
      request.client?.reply(WorkerResponse.withError(WorkerException(msg)));
      print(msg);
      return;
    }

    // retrieve client from the request (must be set)
    final client = request.client;
    if (client == null) {
      print('Missing client for request: $request');
      return;
    }

    final tokenRef = monitor.begin(request);
    try {
      // commands are not available yet (maybe connect() wasn't called or awaited)
      if (operations.isEmpty) {
        client.reply(WorkerResponse.withError(
            WorkerException('Worker service is not ready')));
        return;
      }
      // retrieve operation matching the request command
      final op = operations[request.command];
      if (op == null) {
        // unknown command
        client.reply(WorkerResponse.withError(
            WorkerException('Unknown command: $request')));
        return;
      }
      // process
      dynamic result = op(request);
      if (result is Future) {
        result = await result;
      }
      if (result is Stream) {
        // stream values to the client
        var cancelled = false;
        await for (var res in result) {
          if (cancelled) {
            // cancellation was not handled, so throw
            throw CancelledException(tokenRef?.message);
          }
          client.reply(WorkerResponse(res));
          // Future(noop);
          if (tokenRef?.cancelled ?? false) {
            // the next call may handle cancellation
            cancelled |= true;
          }
        }
      } else {
        // send result to client
        client.reply(WorkerResponse(result));
      }
    } on WorkerException catch (e) {
      // send worker exception to the client
      client.reply(WorkerResponse.withError(e));
    } catch (e, st) {
      // send exception to the client
      client.reply(WorkerResponse.withError(e, st.toString()));
    } finally {
      // always send a closeStream response to ensure streaming operations are closed
      client.reply(WorkerResponse.closeStream);
      monitor.done(tokenRef);
    }
  }
}
