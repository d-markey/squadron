import 'dart:async';

import 'package:squadron/squadron.dart';

import 'perf_counter.dart';
import 'worker.dart';
import 'worker_exception.dart';

/// Base task class
abstract class Task<T> {
  /// Flag indicating whether the task is actually being executed.
  bool get isRunning;

  /// Flag indicating whether the task has completed.
  bool get isFinished;

  /// Flag indicating whether the task has been cancelled.
  bool get isCancelled;

  /// Duration between the moment the task was posted, and the moment it was assigned to a [Worker].
  Duration get waitTime;

  /// Duration between the moment the task assigned to a [Worker], and the moment it finished executing.
  Duration get runningTime;

  /// Cancels the task. If the task is still pending, cancellation is effective immediately with a [CancelledException].
  /// For a running [ValueTask], cancellation is ignored and the task's [ValueTask.value] will eventually complete.
  /// For a running [StreamTask], cancellation will be effective after receiving the next value and the task's [StreamTask.stream] will emit a [].
  /// It should be noted that cancellation of running tasks will not be notified to platform workers.
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
  WorkerTask.value(this._computer, this._counter, this._onDone, this.token)
      : assert(_computer != null),
        _completer = Completer<T>(),
        _producer = null,
        _streamer = null {
    _submitted = _usTimeStamp();
  }

  /// Creates a new [StreamTask].
  WorkerTask.stream(this._producer, this._counter, this._onDone, this.token)
      : assert(_producer != null),
        _streamer = StreamController<T>(),
        _computer = null,
        _completer = null {
    _submitted = _usTimeStamp();
  }

  static int _usTimeStamp() => DateTime.now().microsecondsSinceEpoch;

  late final int _submitted;

  final CancellationToken? token;

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
      microseconds: (_executed ?? _cancelled ?? _usTimeStamp()) - _submitted);

  @override
  Duration get runningTime => _executed == null
      ? Duration.zero
      : Duration(
          microseconds: (_cancelled ?? _finished ?? _usTimeStamp()) - _executed!);

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
      token?.stop();
      _cancelled = _usTimeStamp();
      if (_executed == null) {
        if (_completer != null) {
          _wrapUp(() => _completeWithError(CancelledException(message)), false);
        }
        if (_streamer != null) {
          _wrapUp(() => _close(CancelledException(message)), false);
        }
      }
    }
  }

  void _timeout() {
    if (_finished == null && _cancelled == null) {
      _cancelled = _usTimeStamp();
      if (_completer != null) {
        _wrapUp(() => _completeWithError(TaskTimeoutException('The task timed out.', duration: runningTime)), false);
      }
      if (_streamer != null) {
        _wrapUp(() => _close(TaskTimeoutException('The task timed out.', duration: runningTime)), false);
      }
    }
  }

  void _wrapUp(void Function() wrapper, bool success) async {
    token?.stop();
    if (_finished == null) {
      _finished = _usTimeStamp();
      _counter?.update(_finished! - _executed!, success);
      wrapper();
      if (_onDone != null) {
        _onDone!();
      }
    }
  }

  FutureOr _runFuture(W worker, Future<T> Function(W worker) computer,
      Completer completer) async {
    if (completer.isCompleted) return;

    try {
      if (isCancelled) throw CancelledException(null);
      token?.start(onTimeout: _timeout);
      final value = await computer(worker);
      _wrapUp(() => _completeWithResult(value), true);
    } on WorkerException catch (ex) {
      _wrapUp(() => _completeWithError(ex), false);
    } catch (ex, st) {
      _wrapUp(() => _completeWithError(WorkerException(ex.toString(), stackTrace: st.toString())), false);
    }
  }

  FutureOr _runStream(W worker, Stream<T> Function(W worker) producer,
      StreamController streamer) async {
    if (streamer.isClosed) return;

    try {
      if (isCancelled) throw CancelledException(null);
      token?.start(onTimeout: _timeout);
      _wrapUp(() => _close(), true);
    } on WorkerException catch (ex) {
      _wrapUp(() => _close(ex), false);
    } catch (ex, st) {
      _wrapUp(() => _close(WorkerException(ex.toString(), stackTrace: st.toString())), false);
    }
  }

  FutureOr run(W worker) {
    _executed = _usTimeStamp();
    if (_computer != null && _completer != null) {
      return _runFuture(worker, _computer!, _completer!);
    } else if (_producer != null && _streamer != null) {
      return _runStream(worker, _producer!, _streamer!);
    } else {
      return WorkerException('The worker task state is invalid; cannot run.');
    }
  }

  final PerfCounter? _counter;
  final void Function()? _onDone;

  final Future<T> Function(W worker)? _computer;
  final Completer<T>? _completer;

  @override
  Future<T> get value => _completer!.future;

  final Stream<T> Function(W worker)? _producer;
  final StreamController<T>? _streamer;

  @override
  Stream<T> get stream => _streamer!.stream;
}
