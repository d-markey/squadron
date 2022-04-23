import 'dart:async';

import '../perf_counter.dart';
import '../squadron_exception.dart';
import '../worker.dart';
import '../worker_exception.dart';
import '../worker_task.dart';

import '_worker_task.dart';

class WorkerValueTask<T, W extends Worker> extends WorkerTask<T, W>
    implements ValueTask<T> {
  /// Creates a new [ValueTask].
  WorkerValueTask(this._computer, PerfCounter? counter) : super(counter);

  final Future<T> Function(W worker) _computer;
  final _completer = Completer<T>();

  @override
  Future<T> get value => _completer.future;

  void _completeWithError(SquadronException exception) {
    wrapUp(() {
      if (!_completer.isCompleted) {
        _completer.completeError(exception, exception.stackTrace);
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
      _completeWithError(cancelledException!);
    }
  }

  @override
  Future run(W worker) async {
    await super.run(worker);
    try {
      if (isCancelled) {
        throw CancelledException();
      }
      final value = await _computer(worker);
      _completeWithResult(value);
    } catch (ex, st) {
      _completeWithError(SquadronException.from(error: ex, stackTrace: st));
    }
  }
}
