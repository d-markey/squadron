import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:squadron/squadron.dart';

import 'worker.dart';
import 'worker_task.dart';

/// Worker pool responsible for instantiating, stopping and scheduling workers
/// asynchronously and in parallel.
class WorkerPool<W extends Worker> {
  /// Create a worker pool.
  ///
  /// Workers are instantiated using the provided [_workerFactory].
  ///
  /// The pool will only instantiate workers as needed, up to [maxWorkers].
  ///
  /// The [maxParallel] setting controls how many workloads are distributed
  /// to workers in parallel.
  WorkerPool(this._workerFactory,
      {this.minWorkers = 0, this.maxWorkers = 0, this.maxParallel = 1})
      : assert(minWorkers >= 0),
        assert(maxWorkers >= 0),
        assert(minWorkers <= maxWorkers),
        assert(maxParallel >= 1);

  final W Function() _workerFactory;

  /// Minimum number of live workers
  final int minWorkers;

  /// Maximum number of live workers
  final int maxWorkers;

  /// Maximum work items delivered to workers in parallel
  final int maxParallel;

  final _workers = <W>[];

  /// Current workload
  int get workload => _workers.fold<int>(0, (p, w) => p + w.stats.workload);

  final List<WorkerStat> _deadWorkerStats = <WorkerStat>[];

  /// Maximum workload
  int get maxWorkload => math.max(
      _deadWorkerStats.fold<int>(0, (p, s) => math.max(p, s.maxWorkload)),
      _workers.fold<int>(0, (p, w) => math.max(p, w.stats.maxWorkload)));

  /// Total workload
  int get totalWorkload =>
      _deadWorkerStats.fold<int>(0, (p, s) => p + s.totalWorkload) +
      _workers.fold<int>(0, (p, w) => p + w.stats.totalWorkload);

  /// Number of errors
  int get totalErrors =>
      _deadWorkerStats.fold<int>(0, (p, s) => p + s.totalErrors) +
      _workers.fold<int>(0, (p, w) => p + w.stats.totalErrors);

  /// Number of workers
  int get size => _workers.length;

  /// Maximum number of workers
  int get maxSize => _maxSize;
  int _maxSize = 0;

  /// Ensure at least [minWorkers] workers are started (defaulting to 1 if [minWorkers] is zero).
  Future start() async {
    var count = ((minWorkers == 0) ? 1 : minWorkers) - _workers.length;
    if (count > 0) {
      var newWorkers = <W>[];
      while (count > 0) {
        final worker = _workerFactory();
        await worker.start();
        newWorkers.add(worker);
        count--;
      }
      _workers.addAll(newWorkers);
    }
    _maxSize = math.max(_maxSize, _workers.length);
  }

  bool _removeWorker(Worker worker) {
    if (minWorkers == 0 || _workers.length > minWorkers) {
      if (!worker.isStopped) {
        worker.stop();
      }
      _workers.remove(worker);
      _deadWorkerStats.add(worker.stats);
      return true;
    } else {
      return false;
    }
  }

  /// Stop workers matching the [predicate].
  /// If [predicate] is null or not provided, all workers will be stopped.
  int stop([bool Function(W worker)? predicate]) {
    var targets = _workers.where((w) => !w.isStopped && w.workload == 0);
    if (predicate != null) targets = targets.where(predicate);
    final workersToStop = targets.toList();
    var stopped = 0;
    for (var w in workersToStop) {
      if (_removeWorker(w)) {
        stopped++;
      }
    }
    return stopped;
  }

  final _queue = LinkedList<WorkerTask<W>>();

  /// Gets remaining workload
  int get taskCount => _queue.length;

  /// Registers and schedules a [task] that returns a single value.
  Future<T> compute<T>(Future<T> Function(W worker) task,
      [PerfCounter? counter]) {
    final workerTask = WorkerTask.prepareFuture<T, W>(task, counter, _schedule);
    _queue.add(workerTask);
    Future(() => _schedule());
    return workerTask.future as Future<T>;
  }

  /// Registers and schedules a [task] that returns a stream of values.
  Stream<T> stream<T>(Stream<T> Function(W worker) task,
      [PerfCounter? counter]) {
    final workerTask = WorkerTask.prepareStream<T, W>(task, counter, _schedule);
    _queue.add(workerTask);
    Future(() => _schedule());
    return workerTask.stream as Stream<T>;
  }

  /// The main scheduler
  ///
  /// Steps:
  /// 1. remove stopped workers
  /// 2. if the task queue is not empty:
  ///    1. instantiate up to [maxWorkers] workers (if [maxWorkers] is zero, instanciate as many workers as there are pending tasks)
  ///    2. sort workers by ascending [Worker.workload]
  ///    3. distribute tasks to workers having [Worker.workload] < [maxParallel]
  void _schedule() {
    final workersToRemove = _workers.where((w) => w.isStopped).toList();
    for (var w in workersToRemove) {
      _removeWorker(w);
    }
    if (_queue.isNotEmpty) {
      final max = (maxWorkers > 0 && _queue.length > maxWorkers)
          ? maxWorkers
          : _queue.length;
      while (_workers.length < max) {
        _workers.add(_workerFactory());
      }
      _maxSize = math.max(_maxSize, _workers.length);
      _workers.sort((a, b) => a.workload.compareTo(b.workload));
      for (var i = 0; _queue.isNotEmpty && i < _workers.length; i++) {
        final w = _workers[i];
        if (w.workload < maxParallel) {
          final task = _queue.first;
          _queue.remove(task);
          task.run(w);
        } else {
          break;
        }
      }
    }
  }

  /// Worker statistics
  Iterable<WorkerStat> get stats => _workers.map((w) => w.stats);

  /// Full worker statistics
  Iterable<WorkerStat> get fullStats =>
      _deadWorkerStats.followedBy(_workers.map((w) => w.stats));
}
