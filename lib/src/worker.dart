import 'dart:async';

import 'cancellation_token.dart';
import 'channel.dart';
import 'squadron_exception.dart';
import 'worker_exception.dart';
import 'worker_service.dart';
import 'worker_stat.dart';

/// Base worker class.
///
/// This base class takes care of creating the [Channel] and firing up the worker.
/// Typically, derived classes should add proxy methods sending [WorkerRequest]s to the worker.
abstract class Worker implements WorkerService {
  /// Creates a [Worker] with the specified entrypoint.
  Worker(this._entryPoint, {this.args = const []});

  /// The [Worker]'s entry point.
  /// Typically, a top-level function in native world or a JavaScript Uri in browser world.
  final dynamic _entryPoint;

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
      : Duration(
          microseconds:
              (_stopped ?? DateTime.now().microsecondsSinceEpoch) - _started!);

  /// Idle time.
  Duration get idleTime => (_workload > 0 || _idle == null)
      ? Duration.zero
      : Duration(microseconds: DateTime.now().microsecondsSinceEpoch - _idle!);
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
  WorkerStat get stats => createWorkerStat(
      runtimeType,
      workerId,
      isStopped,
      status,
      workload,
      maxWorkload,
      totalWorkload,
      totalErrors,
      upTime,
      idleTime);

  /// [Channel] to communicate with the worker.
  Channel? get channel => _channel;
  Channel? _channel;
  Future<Channel>? _openChannel;

  /// Worker ID
  String get workerId => _channel?.workerId ?? '<no channel>';

  /// Sends a workload to the worker.
  Future<T> send<T>(int command,
      {List args = const [],
      CancellationToken? token,
      bool inspectRequest = false,
      bool inspectResponse = false}) async {
    // update stats
    _workload++;
    if (_workload > _maxWorkload) {
      _maxWorkload = _workload;
    }

    // ensure the worker is up and running
    late Channel channel;
    if (_channel != null) {
      channel = _channel!;
    } else {
      channel = await start();
    }

    SquadronException? error = token?.exception;
    if (error == null) {
      try {
        // send request and return response
        return await channel.sendRequest<T>(command, args,
            token: token,
            inspectRequest: inspectRequest,
            inspectResponse: inspectResponse);
      } on CancelledException catch (e) {
        error =
            (token?.exception ?? e).withWorkerId(workerId).withCommand(command);
      } catch (e, st) {
        error = SquadronException.from(e, st, workerId, command);
      } finally {
        // update stats
        _workload--;
        _totalWorkload++;
        _idle = DateTime.now().microsecondsSinceEpoch;
      }
    }
    // an error occured: update stats and throw exception
    _totalErrors++;
    throw error;
  }

  /// Sends a streaming workload to the worker.
  Stream<T> stream<T>(int command,
      {List args = const [],
      CancellationToken? token,
      bool inspectRequest = false,
      bool inspectResponse = false}) {
    // update stats
    _workload++;
    if (_workload > _maxWorkload) {
      _maxWorkload = _workload;
    }

    bool done = false;
    void onDone() {
      if (!done) {
        done = true;
        _workload--;
        _totalWorkload++;
        _idle = DateTime.now().microsecondsSinceEpoch;
      }
    }

    final channel = _channel;
    if (channel == null) {
      // worker has not started yet: start it and forward the stream via a StreamController
      late final StreamController<T> controller;
      controller = StreamController<T>(onListen: () async {
        try {
          final channel = await start();
          await controller.addStream(channel.sendStreamingRequest<T>(
            command,
            args,
            onDone: onDone,
            token: token,
            inspectRequest: inspectRequest,
            inspectResponse: inspectResponse,
          ));
        } catch (ex, st) {
          controller.addError(SquadronException.from(ex, st), st);
        } finally {
          controller.close();
          onDone();
        }
      });
      return controller.stream;
    } else {
      // worker has started: return the stream directly
      return channel.sendStreamingRequest<T>(
        command,
        args,
        onDone: onDone,
        token: token,
        inspectRequest: inspectRequest,
        inspectResponse: inspectResponse,
      );
    }
  }

  /// Creates a [Channel] and starts the worker using the [_entryPoint].
  Future<Channel> start() async {
    if (_stopped != null) {
      throw WorkerException('worker is stopped', workerId: workerId);
    }
    if (_channel == null) {
      _openChannel ??= Channel.open(_entryPoint, args);
      final channel = await _openChannel!;
      if (_channel == null) {
        _channel = channel;
        _started = DateTime.now().microsecondsSinceEpoch;
        _idle = _started;
      }
    }
    return _channel!;
  }

  /// Stops this worker.
  void stop() {
    if (_stopped == null) {
      _stopped = DateTime.now().microsecondsSinceEpoch;
      _openChannel = null;
      _channel?.close();
      _channel = null;
    }
  }

  /// Workers do not need an [operations] map.
  @override
  Map<int, CommandHandler> get operations => WorkerService.noOperations;
}
