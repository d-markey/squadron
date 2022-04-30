import '../worker.dart';
import '../worker_pool.dart';
import '../worker_stat.dart';

import '_worker_task.dart';

/// Class representing a [Worker] from a [WorkerPool].
class PoolWorker<W extends Worker> {
  /// Constructs a new [PoolWorker].
  PoolWorker(this.worker, this._maxWorkload) : _capacity = _maxWorkload;

  /// The [Worker] associated to this [PoolWorker].
  final W worker;

  final int _maxWorkload;
  int? _lastStart;
  int _capacity;

  /// The current capacity of this [PoolWorker].
  int get capacity => _capacity;

  /// Whether this [PoolWorker] is stopped or doing nothing.
  bool get isIdle => worker.isStopped || _capacity == _maxWorkload;

  /// Run the specified [task] in the [worker].
  Future run(WorkerTask task) {
    _lastStart = DateTime.now().millisecondsSinceEpoch;
    _capacity--;
    return task.run(worker).whenComplete(() {
      _capacity++;
      if (_capacity == _maxWorkload) {
        _lastStart = null;
      }
    });
  }

  /// Compares [PoolWorker] instances by capacity (descending) and last execution (ascending).
  static int compareCapacityDesc(PoolWorker a, PoolWorker b) {
    if (a.capacity != b.capacity) return b.capacity.compareTo(a.capacity);
    if (a._lastStart == null) return 1;
    if (b._lastStart == null) return -1;
    return a._lastStart!.compareTo(b._lastStart!);
  }

  static bool isStopped(PoolWorker w) => w.worker.isStopped;
  static WorkerStat getStats(PoolWorker w) => w.worker.stats;
}
