import 'dart:async';

import '../perf_counter.dart';
import '../worker.dart';
import '../worker_exception.dart';
import '../worker_pool.dart';
import '../worker_service.dart';
import '../worker_task.dart';

/// [WorkerTask] registered in the [WorkerPool].
abstract class WorkerTask<T, W extends Worker> implements Task<T> {
  WorkerTask(this._counter) : submitted = _timeStamp();

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
          microseconds: (_cancelled ?? _finished ?? _timeStamp()) - _executed!);

  @override
  Duration get waitTime => Duration(
      microseconds: (_executed ?? _cancelled ?? _timeStamp()) - submitted);

  @override
  void cancel([String? message]) {
    _cancelled ??= _timeStamp();
    _cancelledException ??= CancelledException(message: message);
  }

  Future run(W worker) async {
    _executed ??= _timeStamp();
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
      _finished = _timeStamp();
      _counter?.update(_finished! - _executed!, success);
      callback();
    }
  }

  static int _timeStamp() => DateTime.now().microsecondsSinceEpoch;
}
