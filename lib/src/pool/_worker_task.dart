import 'dart:async';

import '../_impl/xplat/_time_stamp.dart';
import '../exceptions/task_canceled_exception.dart';
import '../stats/perf_counter.dart';
import '../worker/worker.dart';
import 'task.dart';
import 'worker_pool.dart';

/// [WorkerTask] registered in the [WorkerPool].
abstract class WorkerTask<T, W extends Worker> implements Task<T> {
  WorkerTask(this._counter) : submitted = microsecTimeStamp();

  final int submitted;
  int? _scheduled;
  int? _finished;
  int? _canceled;

  final PerfCounter? _counter;

  final _done = Completer<void>();

  /// Returns a future that will complete when the task has run.
  @override
  Future<void> get done => _done.future;

  @override
  bool get isCanceled => _canceled != null;

  @override
  bool get isPending => _scheduled == null && _canceled == null;

  @override
  bool get isFinished =>
      _scheduled != null && _finished != null && _canceled == null;

  @override
  bool get isRunning =>
      _scheduled != null && _finished == null && _canceled == null;

  @override
  Duration get runningTime => _scheduled == null
      ? Duration.zero
      : Duration(
          microseconds:
              (_canceled ?? _finished ?? microsecTimeStamp()) - _scheduled!);

  @override
  Duration get waitTime => Duration(
      microseconds:
          (_scheduled ?? _canceled ?? microsecTimeStamp()) - submitted);

  TaskCanceledException? _canceledException;
  TaskCanceledException? get canceledException => _canceledException;

  void throwIfCanceled() {
    if (_canceledException != null) throw _canceledException!;
  }

  @override
  void cancel([String? message]) {
    _canceled ??= microsecTimeStamp();
    _canceledException ??= TaskCanceledException(message);
    if (_scheduled == null) {
      // task will not be scheduled, make sure it reports as completed
      _done.complete();
    }
  }

  void _success(bool res) {
    _finished ??= microsecTimeStamp();
    _counter?.update(_finished! - _scheduled!, res);
    _done.complete();
  }

  void _error(_) {
    _finished ??= microsecTimeStamp();
    _counter?.update(_finished! - _scheduled!, false);
    _done.complete();
  }

  Future<void> run(W worker) async {
    _scheduled ??= microsecTimeStamp();

    return execute(worker).then(_success, onError: _error);
  }

  Future<bool> execute(W worker);
}
