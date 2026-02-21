import '../stats/worker_stat.dart';
import '../worker/worker.dart';
import '_worker_task.dart';
import 'worker_pool.dart';

/// Class representing a [Worker] from a [WorkerPool].
class PoolWorker<W extends Worker> {
  /// Constructs a new [PoolWorker].
  PoolWorker(this.worker, this._maxWorkload) : _capacity = _maxWorkload;

  /// The [Worker] associated to this [PoolWorker].
  final W worker;

  final int _maxWorkload;
  int? _lastStart;
  int _capacity;

  static int _startSequence = 0;

  /// The current capacity of this [PoolWorker].
  int get capacity => _capacity;

  /// Whether this [PoolWorker] is stopped or idle.
  bool get isIdle => worker.isStopped || _capacity == _maxWorkload;

  /// Whether this [PoolWorker] is stopped.
  bool get isStopped => worker.isStopped;

  /// Run the specified [task] in the [worker].
  Future<void> run(WorkerTask task) {
    _lastStart = _startSequence++;
    _capacity--;
    return task.run(worker).whenComplete(() {
      _capacity++;
      if (_capacity == _maxWorkload) {
        _lastStart = null;
      }
    });
  }

  /// Compares [PoolWorker] instances by capacity (descending) and last execution (ascending).
  static int compareCapacity(PoolWorker a, PoolWorker b) {
    if (a.capacity != b.capacity) return a.capacity.compareTo(b.capacity);
    if (a._lastStart == b._lastStart) return 0;
    if (a._lastStart == null) return -1;
    if (b._lastStart == null) return 1;
    return b._lastStart!.compareTo(a._lastStart!);
  }

  static WorkerStat getStats(PoolWorker w) => w.worker.getStats();
}
