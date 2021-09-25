import 'dart:async';
import 'dart:collection';

import 'package:squadron/squadron.dart';

import 'worker.dart';
import 'worker_task.dart';

/// Worker pool responsible for instantiating, stopping and scheduling workers
/// asynchronously and in parallel.
class WorkerPool<W extends Worker> {
  /// Builds a worker pool.
  ///
  /// Workers are instantiated with [_workerFactory].
  ///
  /// The pool will only instantiate workers as needed, up to [maxWorkers].
  ///
  /// The [maxParallel] setting controls how many workloads are distributed
  /// to workers in parallel.
  WorkerPool(this._workerFactory, {this.maxWorkers = 0, this.maxParallel = 1}) : assert(maxWorkers >= 0), assert(maxParallel >= 1);

  final W Function() _workerFactory;

  /// Maximum number of live workers
  final int maxWorkers;

  /// Maximum work items delivered to workers in parallel
  final int maxParallel;

  final _workers = <W>[];

  /// Number of workers
  int get size => _workers.length;

  /// Starts a pool of workers
  Future start() async {
    var count = (maxWorkers == 0) ? 1 : maxWorkers;
    while (count > 0) {
      final worker = _workerFactory();
      await worker.start();
      _workers.add(worker);
      count--;
    }
  }

  /// Stops workers
  void stop([bool Function(W worker)? predicate]) {
    Iterable<W> targets = _workers;
    if (predicate != null) targets = targets.where(predicate);
    for (var w in targets.toList()) {
      w.stop();
      _workers.remove(w);
    }
  }

  // ignore: prefer_collection_literals
  final _queue = LinkedList<WorkerTask<W>>();

  /// Gets remaining work
  int get taskCount => _queue.length;

  /// Registers and schedules a task to be executed by a worker
  Future<T> compute<T>(Future<T> Function(W worker) computation, [ PerfCounter? counter ]) {
    final task = WorkerTask.prepareFuture<T, W>(computation, counter, _schedule);
    _queue.add(task);
    Future(() => _schedule());
    return task.future as Future<T>;
  }

  /// Registers and schedules a task to be executed by a worker
  Stream<T> stream<T>(Stream<T> Function(W worker) computation, [ PerfCounter? counter ]) {
    final task = WorkerTask.prepareStream<T, W>(computation, counter, _schedule);
    _queue.add(task);
    Future(() => _schedule());
    return task.stream as Stream<T>;
  }

  /// The main scheduler
  ///
  /// Steps:
  /// If the task queue is not empty:
  ///   1. instantiate up to [maxWorkers] workers by calling [_workerFactory]
  ///   2. sort workers by workload and find those with load < [maxParallel]
  ///   3. distribute tasks to these workers
  ///   4. when a task completes, notify initial caller and schedule next tasks
  void _schedule() {
    for (var i = _workers.length - 1; i >= 0; i--) {
      if (_workers[i].isStopped) {
        _workers.removeAt(i);
      }
    }
    if (_queue.isNotEmpty) {
      final max = (maxWorkers > 0 && _queue.length > maxWorkers) ? maxWorkers : _queue.length;
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
        }
      }
    }
  }

  /// Worker statistics
  Iterable<WorkerStat> get stats => _workers.map((w) => w.stats);
}
