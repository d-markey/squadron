import 'dart:async';
import 'dart:collection';

import 'concurrency_settings.dart';
import 'squadron.dart';
import 'squadron_exception.dart';
import 'worker.dart';
import 'perf_counter.dart';
import 'worker_service.dart';
import 'worker_stat.dart';

import 'worker_task.dart';

part '_pool_worker.dart';

/// Worker pool responsible for instantiating, starting and stopping workers running in parallel.
/// A [WorkerPool] is also responsible for creating and assigning [WorkerTask]s to [Worker]s.
class WorkerPool<W extends Worker> implements WorkerService {
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

  final _workers = <_PoolWorker<W>>[];

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

  Future<void> _provisionWorkers(int count) async {
    if (_workers.length < count) {
      final tasks = <Future>[];
      while (_workers.length < count) {
        final poolWorker =
            _PoolWorker(_workerFactory(), concurrencySettings.maxParallel);
        _workers.add(poolWorker);
        tasks.add(poolWorker.worker.start());
      }
      await Future.wait(tasks);
      if (_workers.length > _maxSize) {
        _maxSize = _workers.length;
      }
    }
  }

  /// Ensure at least [ConcurrencySettings.minWorkers] workers are started
  /// (defaulting to 1 if [ConcurrencySettings.minWorkers] is zero).
  Future start() {
    _stopped = false;
    return _provisionWorkers(concurrencySettings.min(0));
  }

  int _removeWorker(_PoolWorker poolWorker, bool force) {
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
    List<_PoolWorker<W>> targets;
    bool force;
    if (predicate != null) {
      // kill workers that are idle and satisfy the predicate
      targets = _workers.where((w) => w.isIdle && predicate(w.worker)).toList();
      force = false;
    } else {
      // kill workers while keeping enough workers alive to process pending tasks
      targets = _workers.skip(_queue.length).toList();
      _stopped = true;
      force = true;
    }
    var stopped = 0;
    for (var poolWorker in targets) {
      stopped += _removeWorker(poolWorker, force);
    }
    return stopped;
  }

  final _queue = Queue<WorkerTask>();
  final _executing = <int, WorkerTask>{};

  /// Gets remaining workload
  int get pendingWorkload => _queue.length;

  WorkerTask<T, W> _enqueue<T>(WorkerTask<T, W> task) {
    if (_stopped) {
      throw SquadronException(
          'The pool cannot accept new requests because it is stopped.');
    }
    _queue.addLast(task);
    _schedule();
    return task;
  }

  /// Registers and schedules a [task] that returns a single value.
  @Deprecated('use execute() instead')
  Future<T> compute<T>(Future<T> Function(W worker) task,
          {PerfCounter? counter}) =>
      execute(task, counter: counter);

  /// Registers and schedules a [task] that returns a single value.
  /// Returns a future that completes with the task's value.
  Future<T> execute<T>(Future<T> Function(W worker) task,
          {PerfCounter? counter}) =>
      scheduleTask(task, counter: counter).value;

  /// Registers and schedules a [task] that returns a stream of values.
  /// Returns a stream containing the task's values.
  Stream<T> stream<T>(Stream<T> Function(W worker) task,
          {PerfCounter? counter}) =>
      scheduleStream(task, counter: counter).stream;

  void _onTaskStart(WorkerTask task) {
    _executing[task.hashCode] = task;
  }

  void _onTaskDone(WorkerTask task) {
    _executing.remove(task.hashCode);
    _schedule();
  }

  /// Registers and schedules a [task] that returns a single value.
  /// Returns a [ValueTask]<T>.
  ValueTask<T> scheduleTask<T>(Future<T> Function(W worker) task,
          {PerfCounter? counter}) =>
      _enqueue<T>(WorkerTask.value(_onTaskStart, task, counter, _onTaskDone));

  /// Registers and schedules a [task] that returns a stream of values.
  /// Returns a [StreamTask]<T>.
  StreamTask<T> scheduleStream<T>(Stream<T> Function(W worker) task,
          {PerfCounter? counter}) =>
      _enqueue<T>(WorkerTask.stream(_onTaskStart, task, counter, _onTaskDone));

  Timer? _timer;

  /// The scheduler.
  ///
  /// Steps:
  /// 1. remove stopped workers.
  /// 2. remove cancelled tasks.
  /// 3. if the task queue is not empty:
  ///    (a) instantiate up to [maxWorkers] workers (if [maxWorkers] is zero, instanciate as many workers as there are pending tasks).
  ///    (b) find max capacity available in the pool
  ///    (c) distribute tasks to workers starting with workers with highest [PoolWorker.capacity], as long as [PoolWorker.capacity] > 0.
  void _schedule() {
    if (_timer?.isActive ?? false) {
      // ignore if the last scheduling request has not executed yet
      return;
    }
    _timer = Timer(Duration.zero, () {
      _workers.removeWhere(_PoolWorker.isStopped);
      _queue.removeWhere((t) => t.isCancelled);
      if (_queue.isNotEmpty) {
        scheduleMicrotask(() {
          _provisionWorkers(concurrencySettings.max(_queue.length)).then((_) {
            int maxCapacity;
            while (_queue.isNotEmpty && (maxCapacity = _getMaxCapacity()) > 0) {
              if (maxCapacity > 1) {
                maxCapacity -= 1;
              }
              for (var idx = 0;
                  idx < _workers.length && _queue.isNotEmpty;
                  idx++) {
                final w = _workers[idx];
                if (w.capacity >= maxCapacity) {
                  w.run(_queue.removeFirst());
                }
              }
            }
            if (_stopped) {
              stop();
            }
          }).catchError((ex) {
            Squadron.severe('provisionning workers failed with error $ex');
            while (_queue.isNotEmpty) {
              final task = _queue.removeFirst();
              task.cancel('provisionning workers failed');
            }
          });
        });
      }
    });
  }

  int _getMaxCapacity() {
    _workers.sort(_PoolWorker.compareCapacityDesc);
    return _workers.first.capacity;
  }

  /// Task cancellation. If a specific [task] is provided, only this task will be cancelled.
  /// Otherwise, all tasks registered with the [WorkerPool] are cancelled.
  void cancel([Task? task, String? message]) {
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
      workerTask?.cancel(message);
    } else {
      final cancelled = _executing.values.followedBy(_queue).toList();
      _executing.clear();
      _queue.clear();
      for (var task in cancelled) {
        task.cancel(message);
      }
    }
  }

  /// Worker statistics.
  Iterable<WorkerStat> get stats => _workers.map(_PoolWorker.getStats);

  /// Full worker statistics.
  Iterable<WorkerStat> get fullStats => _deadWorkerStats.followedBy(stats);

  /// Worker pools do not need an [operations] map.
  @override
  final Map<int, CommandHandler> operations = WorkerService.noOperations;
}
