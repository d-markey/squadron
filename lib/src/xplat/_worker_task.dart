import 'dart:async';

import '../perf_counter.dart';
import '../worker.dart';
import '../worker_exception.dart';
import '../worker_pool.dart';
import '../worker_service.dart';
import '../worker_task.dart';

/// [WorkerTask] registered in the [WorkerPool].
abstract class WorkerTask<T, W extends Worker> implements Task<T> {
  WorkerTask(this._counter) {
    submitted = timeStamp();
  }

  static int timeStamp() => DateTime.now().microsecondsSinceEpoch;

  late final int submitted;

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

  CancelledException? get cancelledException => _cancelledException;
  CancelledException? _cancelledException;

  void throwIfCancelled() {
    final ex = _cancelledException;
    if (ex != null) throw ex;
  }

  @override
  Duration get waitTime => Duration(
      microseconds: (_executed ?? _cancelled ?? timeStamp()) - submitted);

  @override
  Duration get runningTime => _executed == null
      ? Duration.zero
      : Duration(
          microseconds: (_cancelled ?? _finished ?? timeStamp()) - _executed!);

  void wrapUp(SquadronCallback callback, bool success) async {
    if (_finished == null) {
      _finished = timeStamp();
      _counter?.update(_finished! - _executed!, success);
      callback();
    }
  }

  @override
  void cancel([String? message]) {
    _cancelled ??= timeStamp();
    _cancelledException ??=
        CancelledException(message: message, stackTrace: StackTrace.current);
  }

  Future run(W worker) async {
    _executed ??= timeStamp();
    if (isCancelled) {
      throw cancelledException!;
    }
  }

  final PerfCounter? _counter;
}
