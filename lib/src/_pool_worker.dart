part of 'worker_pool.dart';

class _PoolWorker<W extends Worker> {
  _PoolWorker(this.worker, this._maxWorkload) : _capacity = _maxWorkload;

  final W worker;

  final int _maxWorkload;
  int? _lastStart;
  int _capacity;

  int get capacity => _capacity;
  bool get isIdle => worker.isStopped || _capacity == _maxWorkload;

  void _start() {
    _lastStart = DateTime.now().millisecondsSinceEpoch;
    _capacity--;
  }

  void _finish() {
    _capacity++;
    if (_capacity == _maxWorkload) {
      _lastStart = null;
    }
  }

  void run(WorkerTask task) {
    _start();
    task.run(worker).whenComplete(_finish);
  }

  static int compareCapacityDesc(_PoolWorker a, _PoolWorker b) {
    if (a.capacity != b.capacity) return b.capacity.compareTo(a.capacity);
    if (a._lastStart == null) return 1;
    if (b._lastStart == null) return -1;
    return a._lastStart!.compareTo(b._lastStart!);
  }

  static bool isStopped(_PoolWorker w) => w.worker.isStopped;
  static WorkerStat getStats(_PoolWorker w) => w.worker.stats;
}
