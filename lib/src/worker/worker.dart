import 'dart:async';

import 'package:cancelation_token/cancelation_token.dart';
import 'package:logger/logger.dart';
import 'package:meta/meta.dart';
import 'package:using/using.dart';

import '../_impl/xplat/_helpers.dart';
import '../channel.dart';
import '../exceptions/exception_manager.dart';
import '../exceptions/squadron_exception.dart';
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

  final PlatformThreadHook? _threadHook;

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

  /// [Channel] to communicate with the worker.
  Channel? get channel => _channel;
  Channel? _channel;
  Future<Channel>? _openChannel;

  void _enter() {
    _workload++;
    if (_workload > _maxWorkload) {
      _maxWorkload = _workload;
    }
  }

  void _leave() {
    _workload--;
    _totalWorkload++;
    _idle = microsecTimeStamp();
  }

  /// Sends a workload to the worker.
  Future<T> send<T>(
    int command, {
    List args = const [],
    CancelationToken? token,
    bool inspectRequest = false,
    bool inspectResponse = false,
  }) async {
    token?.throwIfCanceled();

    // get the channel, start the worker if necessary
    final channel = _channel ?? await start();
    _enter();
    try {
      return await channel.sendRequest<T>(
        command,
        args,
        token: token?.wrap(),
        inspectRequest: inspectRequest,
        inspectResponse: inspectResponse,
      );
    } catch (_) {
      _totalErrors++;
      rethrow;
    } finally {
      _leave();
    }
  }

  /// Sends a streaming workload to the worker.
  Stream<T> stream<T>(
    int command, {
    List args = const [],
    CancelationToken? token,
    bool inspectRequest = false,
    bool inspectResponse = false,
  }) {
    token?.throwIfCanceled();

    // update stats
    _enter();

    bool done = false;
    void onDone() {
      if (!done) {
        done = true;
        _leave();
      }
    }

    if (_channel != null) {
      // worker is up and running: return the stream directly
      final squadronToken = token?.wrap();
      return _channel!.sendStreamingRequest<T>(
        command,
        args,
        onDone: onDone,
        token: squadronToken,
        inspectRequest: inspectRequest,
        inspectResponse: inspectResponse,
      );
    }

    // worker has not started yet: start it and forward the stream via a StreamController
    late final StreamController<T> controller;
    controller = StreamController<T>(onListen: () async {
      try {
        final channel = _channel ?? await start();
        final squadronToken = token?.wrap();
        await controller.addStream(
          channel.sendStreamingRequest<T>(
            command,
            args,
            onDone: onDone,
            token: squadronToken,
            inspectRequest: inspectRequest,
            inspectResponse: inspectResponse,
          ),
          cancelOnError: false,
        );
      } catch (ex, st) {
        controller.addError(SquadronException.from(ex, st), st);
      } finally {
        await controller.close();
        onDone();
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
    _openChannel ??= Channel.open(
        exceptionManager, channelLogger, _entryPoint, args, _threadHook);
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
  }

  /// Workers do not need an [operations] map.
  @override
  Map<int, CommandHandler> get operations => WorkerService.noOperations;
}

@internal
extension WorkerExt on Worker {
  void setExceptionManager(ExceptionManager exceptionManager) {
    _exceptionManager ??= exceptionManager;
  }
}
