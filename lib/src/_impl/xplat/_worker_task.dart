import 'dart:async';

import '../../exceptions/worker_exception.dart';
import '../../stats/perf_counter.dart';
import '../../worker/worker.dart';
import '../../worker/worker_pool.dart';
import '../../worker/worker_service.dart';
import '../../worker/worker_task.dart';
import '_helpers.dart';

/// [WorkerTask] registered in the [WorkerPool].
abstract class WorkerTask<T, W extends Worker> implements Task<T> {
  WorkerTask(this._counter) : submitted = microsecTimeStamp();

  final int submitted;
  int? _executed;
  int? _finished;
  int? _cancelled;

  CancelledException? _cancelledException;

  final PerfCounter? _counter;

  CancelledException? get cancelledException => _cancelledException;
  @override
  bool get isCancelled => _cancelled != null;

  @override
  bool get isFinished =>
      _executed != null && _finished != null && _cancelled == null;
  @override
  bool get isRunning =>
      _executed != null && _finished == null && _cancelled == null;

  @override
  Duration get runningTime => _executed == null
      ? Duration.zero
      : Duration(
          microseconds:
              (_cancelled ?? _finished ?? microsecTimeStamp()) - _executed!);

  @override
  Duration get waitTime => Duration(
      microseconds:
          (_executed ?? _cancelled ?? microsecTimeStamp()) - submitted);

  @override
  void cancel([String? message]) {
    _cancelled ??= microsecTimeStamp();
    _cancelledException ??= CancelledException(message: message);
  }

  Future run(W worker) async {
    _executed ??= microsecTimeStamp();
    if (isCancelled) {
      throw cancelledException!;
    }
  }

  void throwIfCancelled() {
    final ex = _cancelledException;
    if (ex != null) throw ex;
  }

  void wrapUp(SquadronCallback callback, bool success) async {
    if (_finished == null) {
      _finished = microsecTimeStamp();
      _counter?.update(_finished! - _executed!, success);
      callback();
    }
  }
}
