import 'worker.dart';
import 'worker_stat.dart';
import 'worker_task.dart';

class PoolWorker<W extends Worker> {
  PoolWorker(this.worker, this._maxWorkload) : _capacity = _maxWorkload;

  final W worker;

  final int _maxWorkload;
  int _capacity;

  int get capacity => _capacity;
  bool get isIdle => worker.isStopped || _capacity == _maxWorkload;

  Future run(WorkerTask task) {
    _capacity--;
    return task.run(worker).whenComplete(() => _capacity++);
  }

  static int compareCapacityDesc(PoolWorker a, PoolWorker b) =>
      b.capacity.compareTo(a.capacity);

  static bool isStopped(PoolWorker w) => w.worker.isStopped;
  static WorkerStat getStats(PoolWorker w) => w.worker.stats;
}
