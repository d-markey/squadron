import 'dart:async';
import 'dart:collection';

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
  WorkerPool(this._workerFactory, {this.maxWorkers = 0, this.maxParallel = 1})
      : assert(maxWorkers >= 0),
        assert(maxParallel >= 1);

  final W Function() _workerFactory;

  /// Maximum number of live workers
  final int maxWorkers;

  /// Maximum work items delivered to workers in parallel
  final int maxParallel;

  final _workers = <W>[];

  /// Number of workers
  int get size => _workers.length;

  /// Ensure at least [maxWorkers] workers are started (defaulting to 1 if [maxWorkers] is zero).
  Future start() async {
    var count = ((maxWorkers == 0) ? 1 : maxWorkers) - _workers.length;
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
  }

  /// Stop workers matching the [predicate].
  /// If [predicate] is null or not provided, all workers will be stopped.
  int stop([bool Function(W worker)? predicate]) {
    Iterable<W> targets = _workers;
    if (predicate != null) targets = targets.where(predicate);
    final workersToRemove = targets.toList();
    for (var i = 0; i < workersToRemove.length; i++) {
      final w = workersToRemove[i];
      _workers.remove(w);
      w.stop();
    }
    return workersToRemove.length;
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
    for (var i = _workers.length - 1; i >= 0; i--) {
      if (_workers[i].isStopped) {
        _workers.removeAt(i);
      }
    }
    if (_queue.isNotEmpty) {
      final max = (maxWorkers > 0 && _queue.length > maxWorkers)
          ? maxWorkers
          : _queue.length;
      while (_workers.length < max) {
        _workers.add(_workerFactory());
      }
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
}
