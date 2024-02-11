import 'dart:async';

import '../../exceptions/squadron_exception.dart';
import '../../pool/value_task.dart';
import '../../stats/perf_counter.dart';
import '../../worker/worker.dart';
import '_worker_task.dart';

class WorkerValueTask<T, W extends Worker> extends WorkerTask<T, W>
    implements ValueTask<T> {
  /// Creates a new [ValueTask].
  WorkerValueTask(this._computer, PerfCounter? counter) : super(counter);

  final Future<T> Function(W worker) _computer;
  final _completer = Completer<T>();

  @override
  Future<T> get value => _completer.future;

  void _completeWithError(Object exception, StackTrace stackTrace) {
    final ex = (exception is SquadronException)
        ? exception
        : SquadronException.from(exception, stackTrace);
    wrapUp(() {
      if (!_completer.isCompleted) {
        _completer.completeError(ex, ex.stackTrace);
      }
    }, false);
  }

  void _completeWithResult(dynamic data) {
    wrapUp(() {
      if (!_completer.isCompleted) {
        _completer.complete(data);
      }
    }, true);
  }

  @override
  void cancel([String? message]) {
    super.cancel(message);
    if (!isRunning && !isFinished) {
      _completeWithError(
        canceledException!,
        canceledException?.stackTrace ?? StackTrace.current,
      );
    }
  }

  @override
  Future<void> run(W worker) => super
      .run(worker)
      .then((_) => _computer(worker).then(_completeWithResult))
      .catchError(_completeWithError);
}
