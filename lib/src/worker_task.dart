import 'dart:async';

import 'perf_counter.dart';
import 'cancellation_token.dart';
import 'squadron_error.dart';
import 'squadron_exception.dart';
import 'worker.dart';
import 'worker_exception.dart';
import 'worker_pool.dart';
import 'worker_service.dart';

/// Base worker task class
abstract class Task<T> {
  /// Flag indicating whether the task is actually being executed.
  bool get isRunning;

  /// Flag indicating whether the task has completed.
  bool get isFinished;

  /// Flag indicating whether the task has been cancelled.
  bool get isCancelled;

  /// Duration between the moment the task was posted, and the moment it was assigned to a [Worker].
  Duration get waitTime;

  /// Duration between the moment the task was assigned to a [Worker], and the moment it finished executing.
  Duration get runningTime;

  /// Cancels the task. If the task is still pending, cancellation is effective immediately with a
  /// [CancelledException]. For a running [ValueTask], cancellation is ignored and the task's [ValueTask.value]
  /// will eventually complete. For a running [StreamTask], cancellation will be effective after receiving the
  /// next value and the task's [StreamTask.stream] will be closed. It should be noted that cancellation of
  /// running tasks will not be notified to platform workers. To give running tasks a chance to get notified
  /// of cancellation, a [CancellationToken] should be passed to the tasks at the time they are created.
  void cancel([String? message]);
}

/// Class representing a [Task] returning a single value.
abstract class ValueTask<T> extends Task<T> {
  /// The task's value provided as a [Future].
  Future<T> get value;
}

/// Class representing a [Task] returning a stream of values.
abstract class StreamTask<T> extends Task<T> {
  /// The task's stream.
  Stream<T> get stream;
}

/// [WorkerTask] registered in the [WorkerPool].
class WorkerTask<T, W extends Worker> implements ValueTask<T>, StreamTask<T> {
  /// Creates a new [ValueTask].
  WorkerTask.value(this._computer, this._counter)
      : assert(_computer != null),
        _completer = Completer<T>(),
        _producer = null,
        _streamer = null {
    _submitted = _timeStamp();
  }

  /// Creates a new [StreamTask].
  WorkerTask.stream(this._producer, this._counter)
      : assert(_producer != null),
        _streamer = StreamController<T>(),
        _computer = null,
        _completer = null {
    _submitted = _timeStamp();
  }

  static int _timeStamp() => DateTime.now().microsecondsSinceEpoch;

  late final int _submitted;

  @override
  bool get isRunning =>
      _executed != null && _finished == null && _cancelled == null;
  int? _executed;

  @override
  bool get isFinished =>
      _executed != null && _finished != null && _cancelled == null;
  int? _finished;

  @override
  bool get isCancelled => _cancelled != null;
  int? _cancelled;

  @override
  Duration get waitTime => Duration(
      microseconds: (_executed ?? _cancelled ?? _timeStamp()) - _submitted);

  @override
  Duration get runningTime => _executed == null
      ? Duration.zero
      : Duration(
          microseconds: (_cancelled ?? _finished ?? _timeStamp()) - _executed!);

  void _completeWithError(Exception exception) {
    if (!_completer!.isCompleted) {
      _completer!.completeError(exception);
    }
  }

  void _completeWithResult(dynamic data) {
    if (!_completer!.isCompleted) {
      _completer!.complete(data);
    }
  }

  void _close([Exception? exception]) {
    if (!_streamer!.isClosed) {
      if (exception != null) {
        _streamer!.addError(exception);
      }
      _streamer!.close();
    }
  }

  @override
  void cancel([String? message]) {
    if (_cancelled == null) {
      _cancelled = _timeStamp();
      if (_completer != null && _executed == null) {
        _wrapUp(() => _completeWithError(CancelledException(message: message)),
            false);
      } else if (_streamer != null) {
        _wrapUp(() => _close(CancelledException(message: message)), false);
      }
    }
  }

  void _wrapUp(SquadronCallback wrapper, bool success) async {
    if (_finished == null) {
      _finished = _timeStamp();
      _counter?.update(_finished! - _executed!, success);
      wrapper();
    }
  }

  Future _runFuture(W worker, Future<T> Function(W worker) computer,
      Completer completer) async {
    if (completer.isCompleted) return;

    try {
      if (isCancelled) throw CancelledException();
      final value = await computer(worker);
      _wrapUp(() => _completeWithResult(value), true);
    } catch (ex, st) {
      final wex = SquadronException.from(error: ex, stackTrace: st);
      _wrapUp(() => _completeWithError(wex), false);
    }
  }

  Future _runStream(W worker, Stream<T> Function(W worker) producer,
      StreamController streamer) async {
    if (streamer.isClosed) return;

    try {
      if (isCancelled) throw CancelledException();
      await for (var value in producer(worker)) {
        streamer.add(value);
        if (isCancelled) throw CancelledException();
      }
      _wrapUp(() => _close(), true);
    } catch (ex, st) {
      final wex = SquadronException.from(error: ex, stackTrace: st);
      _wrapUp(() => _close(wex), false);
    }
  }

  Future run(W worker) {
    _executed = _timeStamp();
    if (_computer != null && _completer != null) {
      return _runFuture(worker, _computer!, _completer!);
    } else if (_producer != null && _streamer != null) {
      return _runStream(worker, _producer!, _streamer!);
    } else {
      throw newSquadronError('invalid worker task state');
    }
  }

  final PerfCounter? _counter;

  final Future<T> Function(W worker)? _computer;
  final Completer<T>? _completer;

  @override
  Future<T> get value => _completer!.future;

  final Stream<T> Function(W worker)? _producer;
  final StreamController<T>? _streamer;

  @override
  Stream<T> get stream => _streamer!.stream;
}
