import 'dart:async';

import 'package:cancelation_token/cancelation_token.dart';
import 'package:logger/web.dart';
import 'package:using/using.dart';

import '../_impl/xplat/_forward_completer.dart';
import '../_impl/xplat/_forward_stream_controller.dart';
import '../_impl/xplat/_time_stamp.dart';
import '../channel.dart';
import '../exceptions/exception_manager.dart';
import '../exceptions/squadron_exception.dart';
import '../exceptions/task_terminated_exception.dart';
import '../exceptions/worker_exception.dart';
import '../invoker.dart';
import '../iworker.dart';
import '../stats/worker_stat.dart';
import '../tokens/_squadron_cancelation_token.dart';
import '../typedefs.dart';
import '../worker/worker_request.dart';
import '../worker_service.dart';

part 'worker.stats.dart';

/// Base worker class.
///
/// This base class takes care of creating the [Channel] and firing up the
/// worker. Typically, derived classes should add proxy methods sending
/// [WorkerRequest]s to the worker.
abstract class Worker
    with Releasable
    implements WorkerService, IWorker, Invoker {
  /// Creates a [Worker] with the specified entrypoint.
  Worker(this._entryPoint,
      {PlatformThreadHook? threadHook, ExceptionManager? exceptionManager})
      : _threadHook = threadHook,
        _exceptionManager = exceptionManager {
    _stats = _Stats(this);
  }

  @override
  void release() {
    stop();
    super.release();
  }

  /// The [Worker]'s entry point; typically, a top-level function in native
  /// world or the Uri to a JavaScript file in browser world.
  final EntryPoint _entryPoint;

  @override
  Logger? channelLogger;

  @override
  ExceptionManager get exceptionManager =>
      (_exceptionManager ??= ExceptionManager());
  ExceptionManager? _exceptionManager;

  final PlatformThreadHook? _threadHook;

  /// The [Worker]'s start arguments.
  List? getStartArgs();

  late final _Stats _stats;

  bool get isStopped => _stats.isStopped;

  /// [Worker] statistics.
  @Deprecated('Use getStats()')
  WorkerStat get stats => _stats.snapshot;

  /// [Worker] statistics.
  WorkerStat getStats() => _stats.snapshot;

  /// Returns true if the [Worker] is connected i.e., it has a valid [Channel].
  /// Returns false otherwise.
  bool get isConnected => _channel != null;

  /// Shared [Channel] that can be used to communicate with the worker.
  Channel? getSharedChannel() => _channel?.share();

  Channel? _channel;
  Future<Channel>? _openChannel;

  /// Sends a workload to the worker.
  @override
  Future<dynamic> send(
    int command, {
    List args = const [],
    CancelationToken? token,
    bool inspectRequest = false,
    bool inspectResponse = false,
  }) async {
    token?.throwIfCanceled();

    // get the channel, start the worker if necessary
    final channel = _channel ?? await start();

    final completer = ForwardCompleter();

    final squadronToken = token?.wrap();
    squadronToken?.onCanceled.then((ex) {
      _channel?.cancelToken(squadronToken);
      completer.failure(SquadronException.from(ex, null, command));
    });

    _stats.beginWork();
    completer.future.whenComplete(_stats.endWork).ignore();

    try {
      final res = await channel.sendRequest(
        command,
        args,
        token: squadronToken,
        inspectRequest: inspectRequest,
        inspectResponse: inspectResponse,
      );
      completer.success(res);
    } catch (ex, st) {
      _stats.failed();
      completer.failure(SquadronException.from(ex, st, command));
    }

    return completer.future;
  }

  /// Sends a streaming workload to the worker.
  @override
  Stream<dynamic> stream(
    int command, {
    List args = const [],
    CancelationToken? token,
    bool inspectRequest = false,
    bool inspectResponse = false,
  }) {
    final squadronToken = token?.wrap();

    late final ForwardStreamController controller;

    squadronToken?.onCanceled.then((ex) {
      if (!controller.isClosed) {
        controller.subscription?.cancel();
        controller.safeAddError(SquadronException.from(ex, null, command));
        controller.close();
      }
      _channel?.cancelToken(squadronToken);
    });

    controller = ForwardStreamController(onListen: () async {
      try {
        if (controller.isClosed) return;
        squadronToken?.throwIfCanceled();
        final channel = _channel ?? await start();
        if (controller.isClosed) return;

        _stats.beginWork();
        controller.done.whenComplete(_stats.endWork).ignore();

        controller.attachSubscription(channel
            .sendStreamingRequest(
              command,
              args,
              token: squadronToken,
              inspectRequest: inspectRequest,
              inspectResponse: inspectResponse,
            )
            .listen(
              controller.safeAdd,
              onError: (ex, st) => controller
                  .safeAddError(SquadronException.from(ex, st, command)),
              onDone: controller.close,
              cancelOnError: false,
            ));
      } catch (ex, st) {
        _stats.failed();
        controller.subscription?.cancel();
        controller.safeAddError(SquadronException.from(ex, st, command));
        controller.close();
      }
    });

    return controller.stream;
  }

  /// Creates a [Channel] and starts the worker using the [_entryPoint].
  @override
  Future<Channel> start() {
    if (isStopped) {
      throw WorkerException('Invalid state: worker is stopped');
    }

    if (_channel != null) {
      return Future.value(_channel!);
    }

    return _openChannel ??= Channel.open(
      exceptionManager,
      channelLogger,
      _entryPoint,
      getStartArgs() ?? const [],
      _threadHook,
    ).then((channel) {
      _channel = channel;
      _stats.start();
      return channel;
    });
  }

  /// Stops this worker.
  @override
  void stop() {
    if (!isStopped) {
      channelLogger?.d('Stop worker');
      _stats.stop();
      _openChannel = null;
      _channel?.close();
      _channel = null;
    }
  }

  /// Terminates this worker.
  @override
  void terminate([TaskTerminatedException? ex]) {
    // terminate channel and stop worker
    ex ??= TaskTerminatedException('Worker has been terminated');
    _channel?.terminate(ex);
    stop();
  }

  /// Workers do not need an [operations] map.
  @override
  OperationsMap get operations => WorkerService.noOperations;
}
