import 'dart:async';

import 'package:cancelation_token/cancelation_token.dart';
import 'package:logger/web.dart';
import 'package:using/using.dart';

import '../_impl/xplat/_forward_completer.dart';
import '../_impl/xplat/_forward_stream_controller.dart';
import '../_impl/xplat/_platform.dart'
    if (dart.library.io) '../_impl/native/_platform.dart'
    if (dart.library.html) '../_impl/web/_platform.dart'
    if (dart.library.js_interop) '../_impl/web/_platform.dart' as impl;
import '../_impl/xplat/_time_stamp.dart';
import '../channel.dart';
import '../exceptions/exception_manager.dart';
import '../exceptions/squadron_exception.dart';
import '../exceptions/task_terminated_exception.dart';
import '../exceptions/worker_exception.dart';
import '../iworker.dart';
import '../stats/worker_stat.dart';
import '../tokens/_squadron_cancelation_token.dart';
import '../typedefs.dart';
import '../worker/worker_request.dart';
import '../worker_service.dart';

/// Base worker class.
///
/// This base class takes care of creating the [Channel] and firing up the
/// worker. Typically, derived classes should add proxy methods sending
/// [WorkerRequest]s to the worker.
abstract class Worker with Releasable implements WorkerService, IWorker {
  /// Creates a [Worker] with the specified entrypoint.
  Worker(this._entryPoint,
      {this.args = const [],
      PlatformThreadHook? threadHook,
      ExceptionManager? exceptionManager})
      : _threadHook = threadHook,
        _exceptionManager = exceptionManager;

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

  PlatformThreadHook? _threadHook;

  PlatformThread? _platformThread;

  /// The [Worker]'s start arguments.
  final List args;

  /// Start timestamp (in microseconds since Epoch).
  int? _started;

  /// Stopped timestamp (in microseconds since Epoch).
  int? _stopped;

  /// Current workload.
  int get workload => _workload;
  int _workload = 0;

  /// Maximum acceptable workload.
  int get maxWorkload => _maxWorkload;
  int _maxWorkload = 0;

  /// Total processed workload.
  int get totalWorkload => _totalWorkload;
  int _totalWorkload = 0;

  /// Total errors.
  int get totalErrors => _totalErrors;
  int _totalErrors = 0;

  /// Up time.
  Duration get upTime => (_started == null)
      ? Duration.zero
      : Duration(microseconds: (_stopped ?? microsecTimeStamp()) - _started!);

  /// Idle time.
  Duration get idleTime => (_workload > 0 || _idle == null)
      ? Duration.zero
      : Duration(microseconds: microsecTimeStamp() - _idle!);
  int? _idle;

  /// Indicates if the [Worker] has been stopped.
  bool get isStopped => _stopped != null;

  /// [Worker] status.
  String get status {
    if (isStopped) {
      return 'STOPPED';
    } else if (_workload == 0) {
      return 'IDLE';
    } else {
      return 'WORKING($_workload)';
    }
  }

  /// [Worker] statistics.
  WorkerStat get stats => WorkerStatExt.create(
        runtimeType,
        hashCode,
        isStopped,
        status,
        workload,
        maxWorkload,
        totalWorkload,
        totalErrors,
        upTime,
        idleTime,
      );

  /// Returns true if the [Worker] is connected i.e., it has a valid [Channel].
  /// Returns false otherwise.
  bool get isConnected => _channel != null;

  /// Shared [Channel] that can be used to communicate with the worker.
  Channel? getSharedChannel() => _channel?.share();

  Channel? _channel;
  Future<Channel>? _openChannel;

  final _pendingTasks = <Object>[];

  void _enter(Object task) {
    _pendingTasks.add(task);
    _workload++;
    if (_workload > _maxWorkload) {
      _maxWorkload = _workload;
    }
  }

  void _leave(Object task) {
    _pendingTasks.remove(task);
    _workload--;
    _totalWorkload++;
    _idle = microsecTimeStamp();
  }

  /// Sends a workload to the worker.
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

    _enter(completer);
    completer.future.whenComplete(() => _leave(completer));

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
      _totalErrors++;
      completer.failure(SquadronException.from(ex, st, command));
    }

    return completer.future;
  }

  /// Sends a streaming workload to the worker.
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
        controller.addError(SquadronException.from(ex, null, command));
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
        _enter(controller);
        controller.done.whenComplete(() => _leave(controller));
        controller.attachSubscription(channel
            .sendStreamingRequest(
              command,
              args,
              token: squadronToken,
              inspectRequest: inspectRequest,
              inspectResponse: inspectResponse,
            )
            .listen(
              controller.add,
              onError: (ex, st) =>
                  controller.addError(SquadronException.from(ex, st, command)),
              onDone: controller.close,
              cancelOnError: false,
            ));
      } catch (ex, st) {
        _totalErrors++;
        controller.subscription?.cancel();
        controller.addError(SquadronException.from(ex, st, command));
        controller.close();
      }
    });

    return controller.stream;
  }

  /// Creates a [Channel] and starts the worker using the [_entryPoint].
  @override
  Future<Channel> start() async {
    if (_stopped != null) {
      throw WorkerException('Invalid state: worker is stopped');
    }

    FutureOr<void> threadHook(PlatformThread thread) {
      _platformThread = thread;
      final res = _threadHook?.call(thread);
      _threadHook = null;
      return res;
    }

    _openChannel ??= Channel.open(
        exceptionManager, channelLogger, _entryPoint, args, threadHook);
    final channel = _channel ?? await _openChannel;
    if (_channel == null) {
      _channel = channel;
      _started = microsecTimeStamp();
      _idle = _started;
    }
    return _channel!;
  }

  /// Stops this worker.
  @override
  void stop() {
    if (_stopped == null) {
      _stopped = microsecTimeStamp();
      _openChannel = null;
      _channel?.close();
      _channel = null;
    }
    Future.wait(
      _pendingTasks.map((t) {
        if (t is ForwardCompleter) return t.future;
        if (t is ForwardStreamController) return t.done;
        return null;
      }).nonNulls,
      cleanUp: (_) => _shutdown(),
    ).ignore();
  }

  void _shutdown() {
    if (_platformThread != null) {
      channelLogger?.d('Terminate worker thread');
      impl.terminate(_platformThread!);
      _platformThread = null;
    }
  }

  /// Terminates this worker.
  void terminate() {
    // stop now
    stop();
    // terminate all tasks
    final error = TaskTerminatedException('Worker has been killed');
    final pendingTasks = _pendingTasks.toList();
    for (var task in pendingTasks) {
      if (task is ForwardCompleter) {
        task.failure(error);
      } else if (task is ForwardStreamController) {
        task.subscription?.cancel();
        task.addError(error);
        task.close().ignore();
      }
    }
  }

  /// Workers do not need an [operations] map.
  @override
  Map<int, CommandHandler> get operations => WorkerService.noOperations;
}
