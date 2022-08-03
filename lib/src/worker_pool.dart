import 'dart:async';
import 'dart:collection';

import 'squadron_exception.dart';
import 'worker_exception.dart';
import 'xplat/_pool_worker.dart';
import 'xplat/_worker_stream_task.dart';
import 'xplat/_worker_task.dart';
import 'xplat/_worker_value_task.dart';
import 'concurrency_settings.dart';
import 'squadron.dart';
import 'squadron_error.dart';
import 'worker.dart';
import 'perf_counter.dart';
import 'worker_service.dart';
import 'worker_stat.dart';

import 'worker_task.dart';

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
  WorkerPool(this._workerFactory, {ConcurrencySettings? concurrencySettings})
      : concurrencySettings = concurrencySettings ?? ConcurrencySettings();

  final W Function() _workerFactory;

  /// Concurrency settings.
  final ConcurrencySettings concurrencySettings;

  /// Minimum workers.
  int get minWorkers => concurrencySettings.minWorkers;

  /// Maximum workers.
  int get maxWorkers => concurrencySettings.maxWorkers;

  /// Maximum tasks per worker.
  int get maxParallel => concurrencySettings.maxParallel;

  /// Maximum running tasks.
  int get maxConcurrency => concurrencySettings.maxConcurrency;

  final _workers = <PoolWorker<W>>[];

  final List<WorkerStat> _deadWorkerStats = <WorkerStat>[];

  /// Whether this pool is scheduled for stopping.
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

  Future<void> _provisionWorkers(int workload) async {
    if (workload < minWorkers) {
      // at least minWorkers
      workload = minWorkers;
    } else if (maxWorkers > 0 && workload > maxWorkers) {
      // at most maxWorkers if > 0
      workload = maxWorkers;
    }
    // adjust by _workers.length
    workload -= _workers.length;

    if (workload > 0) {
      final maxWorkload = concurrencySettings.maxParallel;
      final tasks = <Future>[];
      final errors = [];
      for (var i = 0; i < workload; i++) {
        try {
          final poolWorker = PoolWorker(_workerFactory(), maxWorkload);
          tasks.add(
            poolWorker.worker.start().then((_) {
              // start succeeded: register worker
              _workers.add(poolWorker);
              return true;
            }).onError<Object>((ex, st) {
              // start failed
              errors.add(SquadronException.from(ex, st));
              return false;
            }),
          );
        } catch (ex, st) {
          errors.add(SquadronException.from(ex, st));
        }
      }

      await Future.wait(tasks);

      if (_workers.length > _maxSize) {
        _maxSize = _workers.length;
      }
      if (errors.isNotEmpty) {
        if (errors.length >= tasks.length) {
          // all tasks failed: throw
          throw errors.firstWhere((e) => e is SquadronError,
                  orElse: () => null) ??
              errors.firstWhere((e) => e is WorkerException,
                  orElse: () => null) ??
              errors.first;
        } else {
          // some tasks failed: warn
          Squadron.warning(() => 'Error while provisionning workers: $errors');
        }
      }
    }
  }

  /// Ensure at least [ConcurrencySettings.minWorkers] workers are started
  /// (defaulting to 1 if [ConcurrencySettings.minWorkers] is zero).
  Future start() {
    _stopped = false;
    return _provisionWorkers(_queue.isEmpty ? 1 : _queue.length);
  }

  int _removeWorker(PoolWorker poolWorker, bool force) {
    if (_scheduling) return 0;
    if (force || _workers.length > concurrencySettings.minWorkers) {
      final workerId = poolWorker.worker.workerId;
      poolWorker.worker.stop();
      _workers.remove(poolWorker);
      _deadWorkerStats.add(poolWorker.worker.stats.withWorkerId(workerId));
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
    List<PoolWorker<W>> targets;
    bool force = (predicate == null);
    if (force) {
      // kill workers while keeping enough workers alive to process pending tasks
      targets = _workers.skip(_queue.length).toList();
      _stopped = true;
    } else {
      // kill workers that are idle and satisfy the predicate
      targets = _workers.where((w) => w.isIdle && predicate(w.worker)).toList();
    }
    var stopped = 0;
    for (var poolWorker in targets) {
      stopped += _removeWorker(poolWorker, force);
    }
    return stopped;
  }

  final _queue = Queue<WorkerTask>();
  final _executing = <WorkerTask>{};

  /// Gets remaining workload
  int get pendingWorkload => _queue.length;

  WorkerTask<T, W> _enqueue<T>(WorkerTask<T, W> task) {
    if (_stopped) {
      throw newSquadronError(
          'the pool cannot accept new requests because it is stopped');
    }
    _queue.addLast(task);
    _schedule();
    return task;
  }

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

  /// Registers and schedules a [task] that returns a single value.
  /// Returns a [ValueTask]<T>.
  ValueTask<T> scheduleTask<T>(Future<T> Function(W worker) task,
          {PerfCounter? counter}) =>
      _enqueue<T>(WorkerValueTask<T, W>(task, counter)) as ValueTask<T>;

  /// Registers and schedules a [task] that returns a stream of values.
  /// Returns a [StreamTask]<T>.
  StreamTask<T> scheduleStream<T>(Stream<T> Function(W worker) task,
          {PerfCounter? counter}) =>
      _enqueue<T>(WorkerStreamTask<T, W>(task, counter)) as StreamTask<T>;

  Timer? _timer;
  bool _scheduling = false;

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
      _workers.removeWhere(PoolWorker.isStopped);
      _queue.removeWhere((t) => t.isCancelled);
      if (_stopped && _queue.isEmpty && _executing.isEmpty) {
        stop();
      } else if (_queue.isNotEmpty) {
        scheduleMicrotask(() {
          _scheduling = true;
          _provisionWorkers(_queue.length).then((_) {
            int maxCapacity;
            while (_queue.isNotEmpty &&
                (maxCapacity = _sortAndGetMaxCapacity()) > 0) {
              maxCapacity -= 1;
              for (var idx = 0; idx < _workers.length; idx++) {
                final w = _workers[idx];
                if (_queue.isEmpty ||
                    w.capacity == 0 ||
                    w.capacity < maxCapacity) {
                  break;
                }
                final task = _queue.removeFirst();
                _executing.add(task);
                w.run(task).whenComplete(() {
                  _executing.remove(task);
                  _schedule();
                });
              }
            }
            _scheduling = false;
          }).catchError((ex) {
            Squadron.severe('provisionning workers failed with error $ex');
            while (_queue.isNotEmpty) {
              final task = _queue.removeFirst();
              task.cancel('provisionning workers failed');
            }
            _scheduling = false;
          });
        });
      }
    });
  }

  int _sortAndGetMaxCapacity() {
    _workers.sort(PoolWorker.compareCapacityDesc);
    return _workers.first.capacity;
  }

  /// Task cancellation. If a specific [task] is provided, only this task will be cancelled.
  /// Otherwise, all tasks registered with the [WorkerPool] are cancelled.
  void cancel([Task? task, String? message]) {
    if (task != null) {
      _executing.remove(task);
      _queue.removeWhere((t) => t == task);
      task.cancel(message);
    } else {
      final cancelled = _executing.followedBy(_queue).toList();
      _executing.clear();
      _queue.clear();
      for (var task in cancelled) {
        task.cancel(message);
      }
    }
  }

  /// Worker statistics.
  Iterable<WorkerStat> get stats => _workers.map(PoolWorker.getStats);

  /// Full worker statistics.
  Iterable<WorkerStat> get fullStats => _deadWorkerStats.followedBy(stats);

  /// Worker pools do not need an [operations] map.
  @override
  Map<int, CommandHandler> get operations => WorkerService.noOperations;
}
