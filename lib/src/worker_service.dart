import 'dart:async';

import 'channel.dart';
import 'worker_exception.dart';
import 'worker_request.dart';
import 'worker_response.dart';

typedef CommandHandler = FutureOr Function(WorkerRequest req);

abstract class WorkerService {
  Map<int, CommandHandler> get operations;

  /// Called by the platform worker upon startup, in response to a start [WorkerRequest].
  /// [channelInfo] is an opaque object sent back from the platform worker to the Squadron [Worker]
  /// and used to communicate with the platform worker. Typically, [channelInfo] would be a [SendPort]
  /// (native) or a [MessagePort] (browser). [operations] and [serviceOperations] are optional maps of
  /// command ids to command methods. The idea is to provide the actual map of supported commands in
  /// [serviceOperations] and an empty map in [operations]. [operations] will be populated with entries
  /// from [serviceOperations]. If [operations] is not empty, it should mean that [connect] has already
  /// been called.   /// [operations] make it easier to implement the [Worker]'s message handler. See
  /// also [process].
  static void connect(Channel? client, Object channelInfo,
      {Map<int, CommandHandler>? operations,
      Map<int, CommandHandler>? serviceOperations}) {
    if (client == null) {
      print('Missing client for connection request');
      return;
    }
    try {
      if (operations?.isNotEmpty ?? false) {
        client.reply(WorkerResponse.withError(
            'Already connected', StackTrace.current.toString()));
        return;
      }
      client.connect(channelInfo);
      operations?.addAll(serviceOperations ?? {});
    } on WorkerException catch (e) {
      client.reply(WorkerResponse.withError(e.message, e.stackTrace));
    } catch (e, st) {
      client.reply(WorkerResponse.withError(e.toString(), st.toString()));
    }
  }

  /// Generic [WorkerRequest] handler based on a map of command ids/command methods.
  /// [operations] contains a map of command handlers indexed by command ID.
  static void process(
      Map<int, CommandHandler> operations, WorkerRequest request) async {
    // start and termination requests must be handled beforehand
    if (request.connect || request.terminate) {
      request.client?.reply(WorkerResponse.withError(
          'Unhandled start or termination request: $request',
          StackTrace.current.toString()));
      print('Unhandled start or termination request: $request');
      return;
    }

    // retrieve client from the request (must be set)
    final client = request.client;
    if (client == null) {
      print('Missing client for request: $request');
      return;
    }

    try {
      // commands are not available yet (maybe connect() wasn't called or awaited)
      if (operations.isEmpty) {
        client.reply(WorkerResponse.withError(
            'Worker service is not ready', StackTrace.current.toString()));
        return;
      }
      // retrieve operation matching the request command
      final op = operations[request.command];
      if (op == null) {
        // unknown command
        client.reply(WorkerResponse.withError(
            'Unknown command: $request', StackTrace.current.toString()));
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
        client.reply(WorkerResponse.endOfStream());
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
    }
  }
}
