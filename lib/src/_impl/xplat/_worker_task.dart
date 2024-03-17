import 'dart:async';

import '../../exceptions/task_canceled_exception.dart';
import '../../pool/task.dart';
import '../../pool/worker_pool.dart';
import '../../stats/perf_counter.dart';
import '../../worker/worker.dart';
import '../../worker_service.dart';
import '_helpers.dart';

/// [WorkerTask] registered in the [WorkerPool].
abstract class WorkerTask<T, W extends Worker> implements Task<T> {
  WorkerTask(this._counter) : submitted = microsecTimeStamp();

  final int submitted;
  int? _executed;
  int? _finished;
  int? _canceled;

  final PerfCounter? _counter;

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

  @override
  void cancel([String? message]) {
    _canceled ??= microsecTimeStamp();
    _canceledException ??= TaskCanceledException(message);
  }

  static final _ready = Future<void>.value();

  Future<void> run(W worker) {
    _executed ??= microsecTimeStamp();
    return (_canceledException == null)
        ? _ready
        : Future.error(_canceledException!);
  }

  void wrapUp(SquadronCallback callback, bool success) async {
    if (_finished == null) {
      _finished = microsecTimeStamp();
      _counter?.update(_finished! - _executed!, success);
      callback();
    }
  }
}
