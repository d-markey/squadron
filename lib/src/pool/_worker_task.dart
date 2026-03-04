import 'dart:async';

import '../_impl/xplat/_time_stamp.dart';
import '../exceptions/task_canceled_exception.dart';
import '../stats/perf_counter.dart';
import '../utils.dart';
import '../worker/worker.dart';
import 'task.dart';
import 'worker_pool.dart';

/// [WorkerTask] registered in the [WorkerPool].
abstract base class WorkerTask<T, W extends Worker> implements Task<T> {
  WorkerTask(this._counter) : submitted = Timestamp.now();

  final Timestamp submitted;
  Timestamp? _scheduled;
  Timestamp? _finished;
  Timestamp? _canceled;

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
      : (_canceled ?? _finished ?? Timestamp.now()).elapsedSince(_scheduled!);

  @override
  Duration get waitTime =>
      (_scheduled ?? _canceled ?? Timestamp.now()).elapsedSince(submitted);

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
    if (_finished != null || _canceled != null) return;
    _canceled ??= Timestamp.now();
    _canceledException ??= TaskCanceledException(message);
    if (_scheduled == null) {
      // task will not be scheduled, make sure it reports as errored
      _fail();
    }
  }

  void _fail([Object? _]) {
    final finished = _finished ??= Timestamp.now();
    _counter?.update(finished - (_scheduled ?? finished), false);
    _done.safeComplete();
  }

  Future<void> run(W worker) {
    _scheduled ??= Timestamp.now();
    return execute(worker).then(
      (res) {
        _finished ??= Timestamp.now();
        _counter?.update(_finished! - _scheduled!, res);
        _done.safeComplete();
      },
      onError: _fail,
    );
  }

  Future<bool> execute(W worker);
}
