import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'worker.dart';
import 'perf_counter.dart';
import 'worker_stat.dart';
import 'worker_task.dart';

/// Worker pool responsible for instantiating, stopping and scheduling workers
/// asynchronously and in parallel.
class WorkerPool<W extends Worker> {
  /// Create a worker pool.
  ///
  /// Workers are instantiated using the provided [_workerFactory].
  /// The pool will only instantiate workers as needed, up to [maxWorkers].
  /// The [maxParallel] setting controls how many workloads are distributed
  /// to workers in parallel.
  WorkerPool(this._workerFactory,
      {this.minWorkers = 0, this.maxWorkers = 0, this.maxParallel = 1})
      : assert(minWorkers >= 0),
        assert(maxWorkers >= 0),
        assert(minWorkers <= maxWorkers),
        assert(maxParallel >= 1);

  final W Function() _workerFactory;

  /// Minimum number of live workers.
  final int minWorkers;

  /// Maximum number of live workers.
  final int maxWorkers;

  /// Maximum work items delivered to workers in parallel.
  final int maxParallel;

  final _workers = <W>[];

  /// Current workload.
  int get workload => _workers.fold<int>(0, (p, w) => p + w.stats.workload);

  final List<WorkerStat> _deadWorkerStats = <WorkerStat>[];

  /// Maximum workload.
  int get maxWorkload => math.max(
      _deadWorkerStats.fold<int>(0, (p, s) => math.max(p, s.maxWorkload)),
      _workers.fold<int>(0, (p, w) => math.max(p, w.stats.maxWorkload)));

  /// Total workload.
  int get totalWorkload =>
      _deadWorkerStats.fold<int>(0, (p, s) => p + s.totalWorkload) +
      _workers.fold<int>(0, (p, w) => p + w.stats.totalWorkload);

  /// Number of errors.
  int get totalErrors =>
      _deadWorkerStats.fold<int>(0, (p, s) => p + s.totalErrors) +
      _workers.fold<int>(0, (p, w) => p + w.stats.totalErrors);

  /// Number of workers.
  int get size => _workers.length;

  /// Maximum number of workers.
  int get maxSize => _maxSize;
  int _maxSize = 0;

  /// Ensure at least [minWorkers] workers are started (defaulting to 1 if [minWorkers] is zero).
  Future start() {
    final tasks = <Future>[];
    final min = ((minWorkers == 0) ? 1 : minWorkers);
    while (_workers.length < min) {
      final w = _workerFactory();
      _workers.add(w);
      tasks.add(w.start());
    }
    return Future.wait(tasks);
  }

  bool _removeWorker(Worker worker, bool force) {
    if (force || _workers.length > minWorkers) {
      worker.stop();
      _workers.remove(worker);
      _deadWorkerStats.add(worker.stats);
      return true;
    } else {
      return false;
    }
  }

  /// Stop workers matching the [predicate].
  /// If [predicate] is null or not provided, all workers will be stopped.
  /// Returns the number of workers that have been stopped.
  int stop([bool Function(W worker)? predicate]) {
    Iterable<W> targets = _workers;
    var force = true;
    if (predicate != null) {
      force = false;
      targets =
          targets.where((w) => !w.isStopped && w.workload == 0 && predicate(w));
    }
    final workersToStop = targets.toList();
    var stopped = 0;
    for (var w in workersToStop) {
      if (_removeWorker(w, force)) {
        stopped++;
      }
    }
    return stopped;
  }

  final _queue = LinkedList<WorkerTask<W>>();

  /// Gets remaining workload
  int get pendingWorkload => _queue.length;

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

  /// The main scheduler.
  ///
  /// Steps:
  /// 1. remove stopped workers.
  /// 2. if the task queue is not empty:
  ///    (a) instantiate up to [maxWorkers] workers (if [maxWorkers] is zero, instanciate as many workers as there are pending tasks).
  ///    (b) sort workers by ascending [Worker.workload].
  ///    (c) distribute tasks to workers having [Worker.workload] < [maxParallel].
  void _schedule() {
    _workers.removeWhere((w) => w.isStopped);
    if (_queue.isNotEmpty) {
      final max = (maxWorkers == 0 || _queue.length <= maxWorkers)
          ? _queue.length
          : maxWorkers;
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

  /// Worker statistics.
  Iterable<WorkerStat> get stats => _workers.map((w) => w.stats);

  /// Full worker statistics.
  Iterable<WorkerStat> get fullStats =>
      _deadWorkerStats.followedBy(_workers.map((w) => w.stats));
}
