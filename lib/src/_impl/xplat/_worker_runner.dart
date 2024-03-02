import 'dart:async';
import 'dart:isolate';

import 'package:logger/logger.dart';

import '../../exceptions/squadron_error.dart';
import '../../exceptions/squadron_exception.dart';
import '../../local_worker/local_worker.dart';
import '../../tokens/_cancelation_token_ref.dart';
import '../../tokens/_squadron_cancelation_token.dart';
import '../../typedefs.dart';
import '../../worker/worker_channel.dart';
import '../../worker/worker_request.dart';
import '../../worker_service.dart';

class _NoLogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {/* ignore */}
}

class _EmptyLogPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) => const [''];
}

class _NoLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => true;
}

class WorkerRunner {
  /// Constructs a new worker runner.
  WorkerRunner(this._terminate);

  void Function(WorkerRunner) _terminate;

  final logger = Logger(
    filter: _NoLogFilter(),
    printer: _EmptyLogPrinter(),
    output: _NoLogOutput(),
  );

  Map<int, CommandHandler>? _operations;
  ServiceInstaller? _installer;

  final _cancelTokens = <String, CancelationTokenReference>{};

  bool _terminationRequested = false;
  int _executing = 0;

  Map<int, SquadronCallback>? _streamCancelers;
  int _streamId = 0;

  void Function(OutputEvent)? _logForwarder;

  /// Constructs a new worker runner for a [localWorker].
  factory WorkerRunner.use(LocalWorker localWorker) {
    final runner = WorkerRunner((r) => LocalWorker.terminate());
    runner._operations = localWorker.service.operations;
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
    if (startRequest != null) {
      startRequest.unwrapRequestInPlace(logger);
    }
    final client = startRequest?.client;

    _logForwarder = (event) => client?.log(event.origin);
    Logger.addOutputListener(_logForwarder!);

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
      } else if (_operations != null) {
        throw SquadronErrorExt.create('already connected', StackTrace.current);
      }

      WorkerService service;
      final init = initializer(startRequest);
      if (init is Future) {
        service = await init;
      } else {
        service = init;
      }

      if (service.operations.keys.where((k) => k <= 0).isNotEmpty) {
        throw SquadronErrorExt.create(
            'invalid command identifier in service operations map; command ids must be > 0',
            StackTrace.current);
      }
      _operations = service.operations;

      final install = _install(service);
      if (install is Future) {
        await install;
      }

      client.connect(channelInfo);
    } catch (ex, st) {
      client.error(SquadronException.from(ex, st));
    }
  }

  /// [WorkerRequest] handler dispatching commands according to the
  /// [_operations] map.
  void processMessage(List request) async {
    request.unwrapRequestInPlace(logger);
    final client = request.client;

    if (request.isTermination) {
      // terminate the worker
      return _shutdown();
    } else if (request.isTokenCancelation) {
      // cancel a token
      final token = request.cancelToken!;
      return _getTokenRef(token).update(token);
    } else if (request.isStreamCancelation) {
      // cancel a stream
      return _streamCancelers?[request.streamId]?.call();
    } else if (client == null) {
      throw SquadronErrorExt.create(
          'missing client for request: $request', StackTrace.current);
    }

    // start monitoring execution
    final tokenRef = _begin(request);
    try {
      if (request.isConnection) {
        // connection request must be handled beforehand
        throw SquadronErrorExt.create(
            'unexpected connection request: $request', StackTrace.current);
      } else if (_operations == null) {
        // commands are not available yet (maybe connect() wasn't called or awaited)
        throw SquadronErrorExt.create(
            'worker service is not ready', StackTrace.current);
      }

      // find the operation matching the request command
      final op = _operations![request.command];
      if (op == null) {
        throw SquadronErrorExt.create(
            'unknown command: ${request.command}', StackTrace.current);
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
        await _pipe(result, client, reply);
      } else {
        // result is a value: send to the client
        reply(result);
      }
    } catch (ex, st) {
      // error: send to client
      client.error(SquadronException.from(ex, st));
    } finally {
      // stop monitoring execution
      _done(tokenRef);
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
  Future<void> _pipe(
      Stream stream, WorkerChannel client, void Function(dynamic) reply) {
    StreamSubscription? subscription;
    final done = Completer();

    // stream canceler
    void onDone() {
      client.closeStream();
      subscription?.cancel();
      done.complete();
    }

    // register stream canceler callback and connect stream with client
    final streamId = _registerStreamCanceler(onDone);
    reply(streamId);

    // start forwarding messages to the client
    subscription = stream.listen(
      (data) => reply(data),
      onError: (ex, st) => client.error(SquadronException.from(ex, st)),
      onDone: onDone,
      cancelOnError: false,
    );

    return done.future.whenComplete(() => _unregisterStreamCanceler(streamId));
  }

  /// Assigns a stream ID to the stream canceler callback and registers the
  /// callback.
  int _registerStreamCanceler(SquadronCallback canceler) {
    final streamId = ++_streamId;
    (_streamCancelers ??= <int, SquadronCallback>{})[streamId] = canceler;
    return streamId;
  }

  /// Unregisters the stream canceled callback associated to the [streamId].
  void _unregisterStreamCanceler(int streamId) {
    final canceler = _streamCancelers?[streamId];
    if (canceler != null) {
      _streamCancelers?.remove(streamId);
    }
  }

  /// Installs the service if it implements [ServiceInstaller].
  FutureOr<void> _install(WorkerService service) {
    if (service is ServiceInstaller) {
      _installer = service as ServiceInstaller;
      return _installer!.install();
    }
  }

  /// Terminates the worker if there is no pending execution. Otherwise, marks
  /// the worker as terminating and termination will be effective when all
  /// pending executions have completed.
  void _shutdown() {
    if (_executing == 0) {
      _unmount();
    } else {
      _terminationRequested = true;
    }
  }

  void _unmount() {
    if (_installer != null) {
      // uninstall the service if necessary
      try {
        var res = _installer!.uninstall();
        if (res is Future) {
          res
              .onError((ex, st) => {/* swallow excepions */})
              .whenComplete(_exit);
        } else {
          _exit();
        }
      } catch (ex) {/* swallow exceptions*/}
    } else {
      _exit();
    }
  }

  void _exit() {
    _terminate(this);
    if (_logForwarder != null) {
      Logger.removeOutputListener(_logForwarder!);
    }
  }
}
