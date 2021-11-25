import 'dart:async';

import 'cancellation_token.dart';
import 'channel.dart';
import 'worker_exception.dart';
import 'worker_service.dart';
import 'worker_stat.dart';

/// Base worker class.
///
/// This base class takes care of creating the [Channel] and firing up the worker.
/// Typically, derived classes should add proxy methods sending [WorkerRequest]s to the worker.
abstract class Worker {
  /// Creates a [Worker] with the specified entrypoint.
  Worker(this._entryPoint, {String? id, this.args = const []}) {
    this.id = id ?? hashCode.toString();
  }

  /// The [Worker]'s entry point.
  /// Typically, a top-level function in native world or a JavaScript Uri in browser world.
  final dynamic _entryPoint;

  /// The [Worker]'s start arguments.
  final List args;

  /// The [Worker] id.
  late final String id;

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
  WorkerStat get stats => WorkerStat(runtimeType, id, isStopped, status,
      workload, maxWorkload, totalWorkload, totalErrors, upTime, idleTime);

  /// [Channel] to communicate with the worker.
  Channel? get channel => _channel;
  Channel? _channel;
  Future<Channel>? _starting;

  void cancelToken(CancellationToken cancelToken, String? message) async {
    if (_channel == null) {
      var channel = start();
      if (channel is Future) {
        await channel;
      }
    }

    _channel!.cancelToken(cancelToken, message);
  }

  /// Sends a workload to the worker.
  Future<T> send<T>(int command,
      [List args = const [], CancellationToken? cancelToken]) async {
    // ensure the worker is up and running
    if (_channel == null) {
      var channel = start();
      if (channel is Future) {
        await channel;
      }
    }

    try {
      // update stats
      _workload++;
      if (_workload > _maxWorkload) {
        _maxWorkload = _workload;
      }

      // send request and return response
      return await _channel!
          .sendRequest<T>(command, args, cancelToken: cancelToken);
    } on WorkerException catch (e) {
      // update stats and rethrow with worker id
      _totalErrors++;
      throw WorkerException(e.message, stackTrace: e.stackTrace, workerId: id);
    } catch (e, st) {
      // update stats and rethrow as a [WorkerException] with worker id
      _totalErrors++;
      throw WorkerException(e.toString(),
          stackTrace: st.toString(), workerId: id);
    } finally {
      // update stats
      _workload--;
      _totalWorkload++;
      _idle = DateTime.now().microsecondsSinceEpoch;
    }
  }

  /// Sends a streaming workload to the worker.
  Stream<T> stream<T>(int command,
      [List args = const [], CancellationToken? cancelToken]) async* {
    // ensure the worker is up and running
    if (_channel == null) {
      var channel = start();
      if (channel is Future) {
        await channel;
      }
    }

    try {
      // update stats
      _workload++;
      if (_workload > _maxWorkload) {
        _maxWorkload = _workload;
      }

      // send request and stream response items
      await for (var res in _channel!
          .sendStreamingRequest<T>(command, args, cancelToken: cancelToken)) {
        yield res;
      }
    } on WorkerException catch (e) {
      // update stats and rethrow with worker id
      _totalErrors++;
      throw e.withWorkerId(id);
    } catch (e, st) {
      // update stats and rethrow as a [WorkerException] with worker id
      _totalErrors++;
      throw WorkerException(e.toString(),
          stackTrace: st.toString(), workerId: id);
    } finally {
      // update stats
      _workload--;
      _totalWorkload++;
      _idle = DateTime.now().microsecondsSinceEpoch;
    }
  }

  /// Creates a [Channel] and starts the worker using the [_entryPoint].
  FutureOr<Channel> start() {
    if (_stopped != null) {
      throw WorkerException('Worker is stopped', workerId: id);
    }
    if (_channel != null) {
      return _channel!;
    } else {
      _starting ??= Channel.open(_entryPoint, args).then((channel) async {
        _started = DateTime.now().microsecondsSinceEpoch;
        _idle = _started;
        _channel = channel;
        var result = onStarted();
        if (result is Future) {
          await result;
          return channel;
        } else {
          return channel;
        }
      });
      return _starting!;
    }
  }

  /// Method called after the worker has been started.
  /// Override this method to add custom initialization.
  FutureOr onStarted() {}

  /// Stops this worker.
  void stop() {
    if (_stopped == null) {
      _stopped = DateTime.now().microsecondsSinceEpoch;
      _channel?.close();
      _channel = null;
      _starting = null;
    }
  }

  /// workers inheriting from [WorkerService] do not need an [operations] map
  final Map<int, CommandHandler> operations = const {};
}
