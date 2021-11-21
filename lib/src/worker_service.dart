import 'dart:async';

import 'worker_exception.dart';
import 'worker_monitor.dart';
import 'worker_request.dart';
import 'worker_response.dart';

typedef WorkerInitializer = FutureOr<WorkerService> Function(
    WorkerRequest startRequest);

typedef CommandHandler = FutureOr Function(WorkerRequest req);

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
        client.reply(WorkerResponse.withError('Already connected'));
        return;
      }
      if (operations != null && initializer != null) {
        final init = initializer(startRequest);
        final service = (init is Future) ? await init : init;
        operations.addAll(service.operations);
      }
      client.connect(channelInfo);
    } on WorkerException catch (e) {
      client.reply(WorkerResponse.withError(e.message, e.stackTrace));
    } catch (e, st) {
      client.reply(WorkerResponse.withError(e.toString(), st.toString()));
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

    // start request must be handled beforehand
    if (request.connect) {
      final msg = 'Unhandled start or termination request: $request';
      request.client?.reply(WorkerResponse.withError(msg));
      print(msg);
      return;
    }

    // retrieve client from the request (must be set)
    final client = request.client;
    if (client == null) {
      print('Missing client for request: $request');
      return;
    }

    monitor.begin();
    try {
      // commands are not available yet (maybe connect() wasn't called or awaited)
      if (operations.isEmpty) {
        client.reply(WorkerResponse.withError('Worker service is not ready'));
        return;
      }
      // retrieve operation matching the request command
      final op = operations[request.command];
      if (op == null) {
        // unknown command
        client.reply(WorkerResponse.withError('Unknown command: $request'));
        return;
      }
      // process
      final result = op(request);
      if (result is Future) {
        // send future result to the client
        client.reply(WorkerResponse(await result));
      } else if (result is Stream) {
        // stream values to the client
        await for (var res in result) {
          client.reply(WorkerResponse(res));
        }
        // close the stream
        client.reply(WorkerResponse.closeStream);
      } else {
        // send result to client
        client.reply(WorkerResponse(result));
      }
    } on WorkerException catch (e) {
      // send worker exception to the client
      client.reply(WorkerResponse.withError(e.message, e.stackTrace));
    } catch (e, st) {
      // send exception to the client
      client.reply(WorkerResponse.withError(e.toString(), st.toString()));
    } finally {
      monitor.done();
    }
  }
}
