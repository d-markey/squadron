import 'dart:async';

import 'package:logger/web.dart';

import '../../exceptions/squadron_error.dart';
import '../../exceptions/squadron_exception.dart';
import '../../local_worker/local_worker.dart';
import '../../service_installer.dart';
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

  WorkerService? _service;
  OperationsMap? _operations;

  final _cancelTokens = <String, CancelationTokenReference>{};

  bool _terminationRequested = false;
  int _executing = 0;

  final _streamCancelers = <int, StreamCanceler>{};
  int _streamId = 0;

  void Function(OutputEvent)? _logForwarder;

  /// Constructs a new worker runner for a [localWorker].
  factory WorkerRunner.use(LocalWorker localWorker) {
    final runner = WorkerRunner((r) {
      r.internalLogger.t('Terminating local Worker');
      r._service = null;
      r._operations = null;
    });
    runner._service = localWorker;
    runner._operations = localWorker.operations;
    runner._checkOperations();
    return runner;
  }

  void _checkOperations() {
    final invalidKeys = _operations!.keys.where((k) => k <= 0).toList();
    if (invalidKeys.isNotEmpty) {
      throw SquadronErrorImpl.create(
        'Invalid command identifier${(invalidKeys.length > 1) ? 's' : ''} in service operations map: ${invalidKeys.join(', ')}. Command ids must be positive.',
      );
    }
  }

  /// Called by the platform worker upon startup, in response to a start
  /// [WorkerRequest]. [channelInfo] is an opaque object sent back from the
  /// platform worker to the Squadron [Worker] and used to communicate with the
  /// platform worker. Typically, [channelInfo] would be a [SendPort] (native)
  /// or a [MessagePort] (browser). [initializer] is called to build the
  /// [WorkerService] associated to the worker. The runner's [_service] map
  /// will be set with operations from the service.
  Future<void> connect(WorkerRequest? startRequest, PlatformChannel channelInfo,
      WorkerInitializer initializer) async {
    WorkerChannel? channel;
    try {
      startRequest?.unwrapInPlace(internalLogger);
      channel = startRequest?.channel;

      if (startRequest == null) {
        throw SquadronErrorImpl.create('Missing connection request');
      } else if (channel == null) {
        throw SquadronErrorImpl.create('Missing client for connection request');
      }

      if (_logForwarder == null) {
        final logger = channel.log;
        _logForwarder = (event) => logger(event.origin);
        Logger.addOutputListener(_logForwarder!);
      }

      if (!startRequest.isConnection) {
        throw SquadronErrorImpl.create('Connection request expected');
      } else if (_service != null || _operations != null) {
        throw SquadronErrorImpl.create('Already connected');
      }

      _service = await initializer(startRequest);
      _operations = _service!.operations;
      _checkOperations();

      channel.connect(channelInfo);

      if (_service is ServiceInstaller) {
        _installCompleter = Completer()
          ..complete((() async {
            try {
              await (_service as ServiceInstaller).install();
            } catch (ex, st) {
              internalLogger.e(() => 'Service installation failed: $ex');
              channel?.error(ex, st);
              channel?.closeStream();
              _installError = SquadronException.from(ex, st);
            }
          })());
      }
    } catch (ex, st) {
      internalLogger.e(() => 'Connection failed: $ex');
      channel?.error(ex, st);
      _exit();
    }
  }

  Completer<void>? _installCompleter;
  SquadronException? _installError;

  /// [WorkerRequest] handler dispatching commands according to the
  /// [_service] map. Make sure this method doesn't throw.
  void processRequest(WorkerRequest request) async {
    WorkerChannel? channel;
    try {
      request.unwrapInPlace(internalLogger);
      channel = request.channel;

      if (request.isTermination) {
        // terminate the worker
        return _shutdown();
      }

      // check installation result if necessary
      final pendingInstallation = _installCompleter?.future;
      if (pendingInstallation != null) {
        await pendingInstallation;
        _installCompleter = null;
      }

      if (_installError != null) {
        // service installation failed
        throw _installError!;
      }

      // ==== these requests do not send a response ====

      if (request.isTokenCancelation) {
        // cancel a token
        final token = request.cancelToken!;
        return _getTokenRef(token).update(token);
      } else if (request.isStreamCancelation) {
        // cancel a stream
        final canceler = _streamCancelers[request.streamId];
        return canceler?.call();
      }

      // make sure the worker is connected

      if (request.isConnection) {
        // connection requests are handled by connect().
        throw SquadronErrorImpl.create(
            'Unexpected connection request: $request');
      } else if (_operations == null) {
        // commands are not available yet (maybe connect() wasn't called or awaited)
        throw SquadronErrorImpl.create('Worker service is not ready');
      }

      // ==== other requests require a client to send the response ====

      if (channel == null) {
        throw SquadronErrorImpl.create('Missing client for request: $request');
      }

      final token = request.cancelToken;
      token?.throwIfCanceled();

      // start monitoring execution
      final tokenRef = _begin(request);
      try {
        // find the operation matching the request command
        final cmd = request.command, op = _operations![cmd];
        if (op == null) {
          throw SquadronErrorImpl.create('Unknown command: $cmd');
        }

        // process
        var result = op(request);
        if (result is Future) {
          result = await result;
        }

        final reply = request.reply!;
        if (result is Stream && channel.canStream(result)) {
          // result is a stream: forward data to the client
          final replyWithError = channel.error;
          void $postError(Object exception, [StackTrace? stackTrace]) {
            replyWithError(exception, stackTrace, cmd);
          }

          void post(data) {
            try {
              reply(data);
            } catch (ex, st) {
              $postError(ex, st);
            }
          }

          await _pipe(result, channel, post, $postError, token);
        } else {
          // result is a value: send to the client
          reply(result);
        }
      } finally {
        // stop monitoring execution
        _done(tokenRef);
      }
    } catch (ex, st) {
      if (channel != null) {
        channel.error(ex, st, request.command);
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
  Future<void> _pipe(
    Stream<dynamic> stream,
    WorkerChannel channel,
    void Function(dynamic) post,
    void Function(Object exception, [StackTrace? stackTrace]) postError,
    SquadronCancelationToken? token,
  ) {
    late final StreamSubscription subscription;
    final done = Completer();

    late final int streamId;

    // send endOfStream to client
    Future<void> onDone() async {
      _unregisterStreamCanceler(streamId);
      channel.closeStream();
      await subscription.cancel();
      done.complete();
    }

    final bool Function() checkToken;
    if (token == null) {
      checkToken = () => true;
    } else {
      checkToken = () {
        final ex = token.exception;
        if (ex != null) {
          postError(ex);
          onDone();
        }
        return (ex == null);
      };
    }

    // register stream canceler callback and connect stream with client
    streamId = _registerStreamCanceler(onDone);
    post(streamId);
    if (checkToken()) {
      // start forwarding messages to the client
      subscription = stream.listen(
        (data) {
          if (checkToken()) post(data);
        },
        onError: (ex, st) {
          if (checkToken()) postError(ex, st);
        },
        onDone: onDone,
        cancelOnError: false,
      );
    }

    return done.future;
  }

  /// Assigns a stream ID to the stream canceler callback and registers the
  /// callback.
  int _registerStreamCanceler(StreamCanceler canceler) {
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
      if (_service is ServiceInstaller) {
        // check installation result
        final pendingInstallation = _installCompleter?.future;
        if (pendingInstallation != null) {
          await pendingInstallation;
          _installCompleter = null;
        }
        if (_installError == null) {
          // uninstall iif the service installed succesfuly
          await (_service as ServiceInstaller).uninstall();
        }
      }
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
