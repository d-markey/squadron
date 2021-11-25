import 'dart:async';
import 'dart:collection';

import 'cancellation_token.dart';
import 'concurrency_settings.dart';
import 'squadron_exception.dart';
import 'worker.dart';
import 'perf_counter.dart';
import 'worker_service.dart';
import 'worker_stat.dart';

import 'worker_task.dart';
import 'pool_worker.dart';

/// Worker pool responsible for instantiating, starting and stopping workers running in parallel.
/// A [WorkerPool] is also responsible for creating and assigning [WorkerTask]s to [Worker]s.
class WorkerPool<W extends Worker> {
  /// Create a worker pool.
  ///
  /// Workers are instantiated using the provided [_workerFactory].
  /// The pool will only instantiate workers as needed, depending on [concurrencySettings].
  /// The [ConcurrencySettings.minWorkers] and [ConcurrencySettings.maxWorkers] settings control
  /// how many workers will live in the pool. The [ConcurrencySettings.maxParallel] setting
  /// controls how many tasks can be posted to each individual worker in the pool.
  WorkerPool(this._workerFactory,
      {ConcurrencySettings? concurrencySettings,
      @Deprecated('use concurrencySettings instead') int minWorkers = 0,
      @Deprecated('use concurrencySettings instead') int maxWorkers = 0,
      @Deprecated('use concurrencySettings instead') int maxParallel = 1})
      : concurrencySettings = concurrencySettings ??
            ConcurrencySettings(
                minWorkers: minWorkers,
                maxWorkers: maxWorkers,
                maxParallel: maxParallel);

  final W Function() _workerFactory;

  /// Concurrency settings.
  final ConcurrencySettings concurrencySettings;

  final _workers = <PoolWorker<W>>[];

  final List<WorkerStat> _deadWorkerStats = <WorkerStat>[];

  /// Number of workers.
  bool get stopped => _stopped;
  bool _stopped = false;

  /// Number of workers.
  int get size => _workers.length;

  /// Maximum number of workers.
  int get maxSize => _maxSize;
  int _maxSize = 0;

  /// Current workload.
  int get workload => stats.fold<int>(0, (p, w) => p + w.workload);

  /// Maximum workload.
  int get maxWorkload => fullStats.fold<int>(
      0, (p, s) => (p >= s.maxWorkload) ? p : s.maxWorkload);

  /// Total workload.
  int get totalWorkload =>
      fullStats.fold<int>(0, (p, s) => p + s.totalWorkload);

  /// Number of errors.
  int get totalErrors => fullStats.fold<int>(0, (p, s) => p + s.totalErrors);

  FutureOr _provisionWorkers(int count) {
    if (_workers.length < count) {
      List<Future>? tasks;
      while (_workers.length < count) {
        final worker =
            PoolWorker(_workerFactory(), concurrencySettings.maxParallel);
        _workers.add(worker);
        final task = worker.worker.start();
        if (task is Future) {
          tasks ??= <Future>[];
          tasks.add(task as Future);
        }
      }
      if (_workers.length > _maxSize) {
        _maxSize = _workers.length;
      }
      if (tasks != null) {
        return Future.wait(tasks);
      }
    }
  }

  /// Ensure at least [ConcurrencySettings.minWorkers] workers are started
  /// (defaulting to 1 if [ConcurrencySettings.minWorkers] is zero).
  FutureOr start() {
    _stopped = false;
    return _provisionWorkers(concurrencySettings.min(1));
  }

  int _removeWorker(PoolWorker poolWorker, bool force) {
    if (force || _workers.length > concurrencySettings.minWorkers) {
      poolWorker.worker.stop();
      _workers.remove(poolWorker);
      _deadWorkerStats.add(poolWorker.worker.stats);
      return 1;
    } else {
      return 0;
    }
  }

  /// Stop idle pool workers matching the [predicate].
  /// If [predicate] is null or not provided, all workers will be stopped.
  /// Stopping a worker does not interrupt or cancel processing. Workers will
  /// complete pending tasks before shutting down. In the meantime, they will
  /// not receive any new workload.
  /// Returns the number of workers that have been stopped.
  int stop([bool Function(W worker)? predicate]) {
    Iterable<PoolWorker<W>> targets = _workers;
    var force = true;
    if (predicate != null) {
      force = false;
      targets = targets.where((w) => w.isIdle && predicate(w.worker));
    } else {
      _stopped = true;
    }
    var stopped = 0;
    for (var poolWorker in targets.toList()) {
      stopped += _removeWorker(poolWorker, force);
    }
    return stopped;
  }

  final _queue = Queue<WorkerTask>();
  final _executing = <int, WorkerTask>{};

  /// Gets remaining workload
  int get pendingWorkload => _queue.length;

  WorkerTask<T, W> _enqueue<T>(WorkerTask<T, W> task, CancellationToken? token) {
    if (_stopped) {
      throw SquadronException('The pool cannot accept new requests because it is stopped.');
    }
    _queue.add(task);
    if (token != null) {
      token.addListener(() => _cancelToken(token, token.message));
    }
    Future(() => _schedule());
    return task;
  }

  /// Registers and schedules a [task] that returns a single value.
  @Deprecated('use execute() instead')
  Future<T> compute<T>(Future<T> Function(W worker) task,
          {PerfCounter? counter, CancellationToken? token}) =>
      execute(task, counter: counter, token: token);

  /// Registers and schedules a [task] that returns a single value.
  /// Returns a future that completes with the task's value.
  Future<T> execute<T>(Future<T> Function(W worker) task,
          {PerfCounter? counter, CancellationToken? token}) =>
      scheduleTask(task, counter: counter, token: token).value;

  /// Registers and schedules a [task] that returns a stream of values.
  /// Returns a stream containing the task's values.
  Stream<T> stream<T>(Stream<T> Function(W worker) task,
          {PerfCounter? counter, CancellationToken? token}) =>
      scheduleStream(task, counter: counter, token: token).stream;

  /// Registers and schedules a [task] that returns a single value.
  /// Returns a [ValueTask]<T>.
  ValueTask<T> scheduleTask<T>(Future<T> Function(W worker) task,
          {PerfCounter? counter, CancellationToken? token}) =>
      _enqueue<T>(WorkerTask.value(task, counter, _schedule, token), token);

  /// Registers and schedules a [task] that returns a stream of values.
  /// Returns a [StreamTask]<T>.
  StreamTask<T> scheduleStream<T>(Stream<T> Function(W worker) task,
          {PerfCounter? counter, CancellationToken? token}) =>
      _enqueue<T>(WorkerTask.stream(task, counter, _schedule, token), token);

  /// The main scheduler.
  ///
  /// Steps:
  /// 1. remove stopped workers.
  /// 2. if the task queue is not empty:
  ///    (a) instantiate up to [maxWorkers] workers (if [maxWorkers] is zero, instanciate as many workers as there are pending tasks).
  ///    (b) sort workers by ascending [Worker.workload].
  ///    (c) distribute tasks to workers as loong as [Worker.workload] < [maxParallel].
  void _schedule() {
    _workers.removeWhere(PoolWorker.isStopped);
    if (_queue.isNotEmpty) {
      _provisionWorkers(concurrencySettings.max(_queue.length));
      _workers.sort(PoolWorker.compareCapacityDesc);
      while (_queue.isNotEmpty && _workers.first.capacity > 0) {
        final curCapacity = _workers.first.capacity;
        for (var idx = 0, w = _workers[idx];
            idx < _workers.length &&
                w.capacity == curCapacity &&
                _queue.isNotEmpty;
            idx++) {
          final task = _queue.removeFirst();
          if (!task.isCancelled) {
            _executing[task.hashCode] = task;
            w.run(task).whenComplete(() => _executing.remove(task.hashCode));
          }
        }
      }
    }
  }

  void _cancelToken(CancellationToken token, [String? message]) {
    for (var i = 0; i < _workers.length; i++) {
      _workers[i].worker.cancelToken(token, message ?? token.message);
    }
  }

  /// Task cancellation. If a specific [task] is provided, only this task will be cancelled.
  /// Otherwise, all tasks registered with the [WorkerPool] are cancelled.
  void cancel([Task? task]) {
    if (task != null) {
      WorkerTask? workerTask = _executing.remove(task.hashCode);
      if (workerTask == null) {
        _queue.removeWhere((t) {
          if (t == task) {
            workerTask = t;
            return true;
          } else {
            return false;
          }
        });
      }
      workerTask?.cancel();
    } else {
      final cancelled = _executing.values.followedBy(_queue).toList();
      _executing.clear();
      _queue.clear();
      for (var task in cancelled) {
        task.cancel();
      }
    }
  }

  /// Worker statistics.
  Iterable<WorkerStat> get stats => _workers.map(PoolWorker.getStats);

  /// Full worker statistics.
  Iterable<WorkerStat> get fullStats => _deadWorkerStats.followedBy(stats);

  /// worker pools inheriting from [WorkerService] do not need an [operations] map
  final Map<int, CommandHandler> operations = const {};
}
