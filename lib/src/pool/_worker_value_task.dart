import 'dart:async';

import '../exceptions/squadron_exception.dart';
import '../stats/perf_counter.dart';
import '../worker/worker.dart';
import '_worker_task.dart';
import 'value_task.dart';

final class WorkerValueTask<T, W extends Worker> extends WorkerTask<T, W>
    implements ValueTask<T> {
  /// Creates a new [ValueTask].
  WorkerValueTask(this._computer, PerfCounter? counter) : super(counter);

  final Future<T> Function(W worker) _computer;
  final _result = Completer<T>();

  @override
  Future<T> get value => _result.future;

  void _failure(SquadronException exception) {
    if (!_result.isCompleted) {
      _result.completeError(exception);
    }
  }

  void _success(dynamic data) {
    if (!_result.isCompleted) {
      _result.complete(data);
    }
  }

  @override
  void cancel([String? message]) {
    super.cancel(message);
    _failure(canceledException!);
  }

  @override
  Future<bool> execute(W worker) async {
    try {
      throwIfCanceled();
      final res = await _computer(worker);
      _success(res);
      return true;
    } catch (ex, st) {
      _failure(SquadronException.from(ex, st));
      return false;
    }
  }
}
