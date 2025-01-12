import 'dart:async';

import 'package:meta/meta.dart';

import '../_impl/xplat/_time_stamp.dart';
import '../exceptions/task_canceled_exception.dart';
import '../stats/perf_counter.dart';
import '../worker/worker.dart';
import 'task.dart';
import 'worker_pool.dart';

/// [WorkerTask] registered in the [WorkerPool].
abstract base class WorkerTask<T, W extends Worker> implements Task<T> {
  WorkerTask(this._counter) : submitted = microsecTimeStamp();

  final int submitted;
  int? _scheduled;
  int? _finished;
  int? _canceled;

  final PerfCounter? _counter;

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

  final _done = Completer<void>();

  @override
  Future<void> get done => _done.future;

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
      // task will not be scheduled, make sure it reports as errored
      _fail();
    }
  }

  void _success(bool res) {
    _finished ??= microsecTimeStamp();
    _counter?.update(_finished! - _scheduled!, res);
    if (!_done.isCompleted) _done.complete();
  }

  void _fail([Object? _]) {
    _finished ??= microsecTimeStamp();
    _counter?.update(_finished! - _scheduled!, false);
    if (!_done.isCompleted) _done.complete();
  }

  Future<void> run(W worker) {
    _scheduled ??= microsecTimeStamp();
    return execute(worker).then(_success, onError: _fail);
  }

  Future<bool> execute(W worker);
}

@internal
extension WorkerTaskExt on WorkerTask {
  void fail() => _fail();
}
