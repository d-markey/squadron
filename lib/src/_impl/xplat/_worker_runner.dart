import 'dart:async';
import 'dart:isolate';

import 'package:logger/logger.dart';

import '../../exceptions/squadron_error.dart';
import '../../local_worker/local_worker.dart';
import '../../tokens/_cancelation_token_ref.dart';
import '../../tokens/_squadron_cancelation_token.dart';
import '../../typedefs.dart';
import '../../worker/worker_channel.dart';
import '../../worker/worker_request.dart';
import '../../worker_service.dart';
import '_internal_logger.dart';

class WorkerRunner {
  /// Constructs a new worker runner.
  WorkerRunner(this._terminate);

  void Function(WorkerRunner) _terminate;

  final internalLogger = InternalLogger();

  Map<int, CommandHandler>? _operations;
  ServiceInstaller? _installer;

  final _cancelTokens = <String, CancelationTokenReference>{};

  bool _terminationRequested = false;
  int _executing = 0;

  final _streamCancelers = <int, SquadronCallback>{};
  int _streamId = 0;

  void Function(OutputEvent)? _logForwarder;

  /// Constructs a new worker runner for a [localWorker].
  factory WorkerRunner.use(LocalWorker localWorker) {
    final runner = WorkerRunner((r) => r._operations?.clear());
    runner._operations = {...localWorker.service.operations};
    return runner;
  }

  /// Called by the platform worker upon startup, in response to a start
  /// [WorkerRequest]. [channelInfo] is an opaque object sent back from the
  /// platform worker to the Squadron [Worker] and used to communicate with the
  /// platform worker. Typically, [channelInfo] would be a [SendPort] (native)
  /// or a [MessagePort] (browser). [initializer] is called to build the
  /// [WorkerService] associated to the worker. The runner's [_operations] map
  /// will be set with operations from the service.
  Future<void> connect(WorkerRequest? startRequest, PlatformChannel channelInfo,
      WorkerInitializer initializer) async {
    WorkerChannel? client;
    try {
      startRequest?.unwrapInPlace(internalLogger);
      client = startRequest?.client;

      if (startRequest == null) {
        throw SquadronErrorExt.create('Missing connection request');
      } else if (client == null) {
        throw SquadronErrorExt.create('Missing client for connection request');
      }

      if (_logForwarder == null) {
        final logger = client.log;
        _logForwarder = (event) => logger(event.origin);
        Logger.addOutputListener(_logForwarder!);
      }

      if (!startRequest.isConnection) {
        throw SquadronErrorExt.create('Connection request expected');
      } else if (_operations != null) {
        throw SquadronErrorExt.create('Already connected');
      }

      final service = await initializer(startRequest);
      if (service.operations.keys.where((k) => k <= 0).isNotEmpty) {
        throw SquadronErrorExt.create(
          'Invalid command identifier in service operations map; command ids must be > 0',
        );
      }

      _operations = {...service.operations};

      if (service is ServiceInstaller) {
        _installer = service as ServiceInstaller;
        await _installer!.install();
      }

      client.connect(channelInfo);
    } catch (ex, st) {
      internalLogger.e(() => 'Connection failed: $ex');
      client?.error(ex, st);
      _exit();
    }
  }

  /// [WorkerRequest] handler dispatching commands according to the
  /// [_operations] map. Make sure this method doesn't throw.
  void processRequest(WorkerRequest request) async {
    WorkerChannel? client;
    try {
      request.unwrapInPlace(internalLogger);
      client = request.client;

      // ==== these requests do not send a response ====

      if (request.isTermination) {
        // terminate the worker
        return _shutdown();
      } else if (request.isTokenCancelation) {
        // cancel a token
        final token = request.cancelToken!;
        return _getTokenRef(token).update(token);
      } else if (request.isStreamCancelation) {
        // cancel a stream
        return _streamCancelers[request.streamId]?.call();
      }

      // make sure the worker is connected

      if (request.isConnection) {
        // connection requests are handled by connect().
        throw SquadronErrorExt.create(
            'Unexpected connection request: $request');
      } else if (_operations == null) {
        // commands are not available yet (maybe connect() wasn't called or awaited)
        throw SquadronErrorExt.create('Worker service is not ready');
      }

      // ==== other requests require a client to send the response ====

      if (client == null) {
        throw SquadronErrorExt.create('Missing client for request: $request');
      }

      request.cancelToken?.throwIfCanceled();

      // start monitoring execution
      final tokenRef = _begin(request);
      try {
        // find the operation matching the request command
        final op = _operations![request.command];
        if (op == null) {
          throw SquadronErrorExt.create('Unknown command: ${request.command}');
        }

        // process
        var result = op(request);
        if (result is Future) {
          result = await result;
        }

        // send results back with the proper reply method
        final reply = request.reply!;
        if (result is Stream && client.canStream(result)) {
          // result is a stream: forward data to the client
          await _pipe(result, client, reply, request.command);
        } else {
          // result is a value: send to the client
          reply(result);
        }
      } finally {
        // stop monitoring execution
        _done(tokenRef);
      }
    } catch (ex, st) {
      if (client != null) {
        client.error(ex, st, request.command);
      } else {
        internalLogger.e('Unhandled error: $ex');
      }
    }
  }

  CancelationTokenReference _getTokenRef(SquadronCancelationToken? token) =>
      (token == null)
          ? CancelationTokenReference.noToken
          : _cancelTokens.putIfAbsent(
              token.id, () => CancelationTokenReference(token.id));

  /// Starts monitoring execution of this [request]. If the request contains a
  /// cancelation token, it is overridden with a [CancelationTokenReference]
  /// and this reference is returned to the sender. Otherwise, returns
  /// [CancelationTokenReference.noToken].
  CancelationTokenReference _begin(WorkerRequest request) {
    _executing++;
    final token = _getTokenRef(request.cancelToken);
    token.usedBy(request);
    return token;
  }

  /// Stops monitoring execution and releases the [tokenRef].
  void _done(CancelationTokenReference tokenRef) {
    tokenRef.release();
    if (tokenRef.refCount == 0) {
      _cancelTokens.remove(tokenRef.id);
    }
    _executing--;
    if (_terminationRequested && _executing == 0) {
      _unmount();
    }
  }

  /// Forwards stream events to client.
  Future<void> _pipe(Stream<dynamic> stream, WorkerChannel client,
      void Function(dynamic) reply, int command) {
    StreamSubscription? subscription;
    final done = Completer();

    // stream canceler
    Future<void> onDone() async {
      client.closeStream();
      await subscription?.cancel();
      done.complete();
    }

    // register stream canceler callback and connect stream with client
    final streamId = _registerStreamCanceler(onDone);
    reply(streamId);

    // start forwarding messages to the client
    subscription = stream.listen(
      reply,
      onError: (ex, st) => client.error(ex, st, command),
      onDone: onDone,
      cancelOnError: false,
    );

    return done.future.whenComplete(() => _unregisterStreamCanceler(streamId));
  }

  /// Assigns a stream ID to the stream canceler callback and registers the
  /// callback.
  int _registerStreamCanceler(SquadronCallback canceler) {
    final streamId = ++_streamId;
    _streamCancelers[streamId] = canceler;
    return streamId;
  }

  /// Unregisters the stream canceled callback associated to the [streamId].
  void _unregisterStreamCanceler(int streamId) {
    _streamCancelers.remove(streamId);
  }

  /// Terminates the worker if there is no pending execution. Otherwise, marks
  /// the worker as terminating and termination will be effective when all
  /// pending executions have completed.
  void _shutdown() {
    _terminationRequested = true;
    if (_executing == 0) {
      _unmount();
    }
  }

  // should not throw
  void _unmount() async {
    try {
      // uninstall the service if necessary
      await _installer?.uninstall();
    } catch (ex) {
      internalLogger.e('Service uninstallation failed with error: $ex');
    } finally {
      _exit();
    }
  }

  // should not throw
  void _exit() {
    try {
      _terminate(this);
    } catch (ex) {
      internalLogger.e('Worker termination failed with error: $ex');
    }
    if (_logForwarder != null) {
      Logger.removeOutputListener(_logForwarder!);
    }
  }
}
