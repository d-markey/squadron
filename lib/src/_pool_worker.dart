import 'dart:async';

import 'worker.dart';
import 'worker_stat.dart';
import 'worker_task.dart';

class PoolWorker<W extends Worker> {
  PoolWorker(this.worker, this._maxWorkload) : _capacity = _maxWorkload;

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

  Future run(WorkerTask task) {
    _start();
    return task.run(worker).whenComplete(_finish);
  }

  static int compareCapacityDesc(PoolWorker a, PoolWorker b) {
    if (a.capacity != b.capacity) return b.capacity.compareTo(a.capacity);
    if (a._lastStart == null) return 1;
    if (b._lastStart == null) return -1;
    return a._lastStart!.compareTo(b._lastStart!);
  }

  static bool isStopped(PoolWorker w) => w.worker.isStopped;
  static WorkerStat getStats(PoolWorker w) => w.worker.stats;
}
