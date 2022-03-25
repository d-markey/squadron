part of '_bootstrapper_stub.dart';

class _WorkerRunner {
  _WorkerRunner._();

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
    if (message == null) {
      Squadron.severe(
          'null message; for workers running in an Isolate, this may be due to the run() function not receiving the command parameter.');
      return;
    }

    final startRequest = WorkerRequest.deserialize(message);

    Squadron.setId(startRequest.id!);
    Squadron.logLevel = startRequest.logLevel!;
    Squadron.config('received connection request $message');

    final client = startRequest.client;
    if (client == null) {
      Squadron.severe('missing client for connection request');
      return;
    }
    try {
      if (operations?.isNotEmpty ?? false) {
        Squadron.severe('already connected');
        client.reply(
            WorkerResponse.withError(WorkerException('already connected')));
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
      _WorkerMonitor monitor) async {
    Squadron.finest(() => 'processing request $message');
    final request = WorkerRequest.deserialize(message);

    if (request.terminate) {
      monitor.terminate();
      return;
    }

    if (request.cancel) {
      monitor.cancel(request.cancelToken!);
      return;
    }

    // start request must be handled beforehand
    if (request.connect) {
      final msg = 'Unhandled connect request: $message';
      Squadron.warning(msg);
      request.client?.reply(WorkerResponse.withError(WorkerException(msg)));
      return;
    }

    // retrieve client from the request (must be set)
    final client = request.client;
    if (client == null) {
      Squadron.severe('missing client for request: $request');
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
      if (tokenRef?.cancelled ?? false) {
        client.reply(
            WorkerResponse.withError(CancelledException(message: 'Cancelled')));
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
        await for (var res in result) {
          client.reply(WorkerResponse(res));
          if (tokenRef?.cancelled ?? false) {
            client.reply(WorkerResponse.withError(
                CancelledException(message: 'Cancelled')));
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
