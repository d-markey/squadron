import 'dart:async';

import '../_impl/xplat/_helpers.dart';
import '../exceptions/task_canceled_exception.dart';
import '../stats/perf_counter.dart';
import '../worker/worker.dart';
import 'task.dart';
import 'worker_pool.dart';

/// [WorkerTask] registered in the [WorkerPool].
abstract class WorkerTask<T, W extends Worker> implements Task<T> {
  WorkerTask(this._counter) : submitted = microsecTimeStamp();

  final int submitted;
  int? _executed;
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
  bool get isPending => _executed == null && _canceled == null;

  @override
  bool get isFinished =>
      _executed != null && _finished != null && _canceled == null;

  @override
  bool get isRunning =>
      _executed != null && _finished == null && _canceled == null;

  @override
  Duration get runningTime => _executed == null
      ? Duration.zero
      : Duration(
          microseconds:
              (_canceled ?? _finished ?? microsecTimeStamp()) - _executed!);

  @override
  Duration get waitTime => Duration(
      microseconds:
          (_executed ?? _canceled ?? microsecTimeStamp()) - submitted);

  TaskCanceledException? _canceledException;
  TaskCanceledException? get canceledException => _canceledException;

  void throwIfCanceled() {
    if (_canceledException != null) throw _canceledException!;
  }

  @override
  void cancel([String? message]) {
    _canceled ??= microsecTimeStamp();
    _canceledException ??= TaskCanceledException(message);
    if (_executed == null) {
      // task will not be scheduled, make sure it reports as completed
      _done.complete();
    }
  }

  Future<void> run(W worker) async {
    throwIfCanceled();
    _executed ??= microsecTimeStamp();
    var success = false;
    try {
      success = await execute(worker);
    } catch (_) {
      success = false;
      rethrow;
    } finally {
      _finished = microsecTimeStamp();
      if (_canceledException != null) success = false;
      _counter?.update(_finished! - _executed!, success);
      _done.complete();
    }
  }

  Future<bool> execute(W worker);
}
