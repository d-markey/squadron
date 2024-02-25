import 'dart:async';
import 'dart:collection';

import 'package:logger/logger.dart';

import '../_impl/xplat/_pool_worker.dart';
import '../_impl/xplat/_task.dart';
import '../_impl/xplat/_worker_stream_task.dart';
import '../_impl/xplat/_worker_task.dart';
import '../_impl/xplat/_worker_value_task.dart';
import '../concurrency_settings.dart';
import '../exceptions/exception_manager.dart';
import '../exceptions/squadron_error.dart';
import '../exceptions/squadron_exception.dart';
import '../exceptions/worker_exception.dart';
import '../stats/perf_counter.dart';
import '../stats/worker_stat.dart';
import '../worker/worker.dart';
import '../worker_service.dart';
import 'stream_task.dart';
import 'value_task.dart';

typedef WorkerFactory<W> = W Function();

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

  final WorkerFactory<W> _workerFactory;

  Logger? logger;

  ExceptionManager? _exceptionManager;

  ExceptionManager get exceptionManager =>
      (_exceptionManager ??= ExceptionManager());

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

  final _deadWorkerStats = <WorkerStat>[];

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

  final _workerPoolListeners =
      <Object, void Function(W worker, bool removed)>{};

  /// Registers a callback to be invoked when a worker thread is added or removed from the pool.
  Object registerWorkerPoolListener(
      void Function(W worker, bool removed) listener) {
    final token = Object();
    _workerPoolListeners[token] = listener;
    return token;
  }

  /// Unregisters a callback.
  void unregisterWorkerPoolListener(
      {Function(W worker, bool removed)? listener, Object? token}) {
    if (token != null) {
      _workerPoolListeners.remove(token);
    } else if (listener != null) {
      _workerPoolListeners.removeWhere((key, value) => value == listener);
    }
  }

  int _startingWorkers = 0;

  int _getProvisionNeeds(int workload) {
    if (workload < minWorkers) {
      // at least minWorkers
      workload = minWorkers;
    }
    if (maxWorkers > 0 && workload > maxWorkers) {
      // at most maxWorkers if > 0
      workload = maxWorkers;
    }
    // adjust by _workers.length and _startingWorkers
    return workload - _workers.length - _startingWorkers;
  }

  Future<void> _provisionWorkers(int workload) {
    final tasks = <Future>[];
    final errors = [];
    for (var i = 0; i < workload; i++) {
      try {
        final worker = _workerFactory();
        worker.logger = logger;
        worker.setExceptionManager(exceptionManager);

        final poolWorker = PoolWorker(worker, maxParallel);
        _startingWorkers++;
        tasks.add(poolWorker.worker.start().whenComplete(() {
          _startingWorkers--;
        }).then((_) {
          // start succeeded: register worker
          _addWorkerAndNotify(poolWorker);
        }).catchError((ex, st) {
          // start failed, ensure the worker is stopped
          poolWorker.worker.stop();
          errors.add(SquadronException.from(ex, st));
        }));
      } catch (ex, st) {
        errors.add(SquadronException.from(ex, st));
      }
    }

    return Future.wait(tasks).whenComplete(() {
      if (_workers.length > _maxSize) {
        _maxSize = _workers.length;
      }
      if (errors.isNotEmpty) {
        if (errors.length < tasks.length) {
          // some tasks failed: warn
          logger?.e(() => 'Error while provisionning workers: $errors');
        } else {
          // all tasks failed: throw
          throw errors.firstWhere((e) => e is SquadronError,
                  orElse: () => null) ??
              errors.firstWhere((e) => e is WorkerException,
                  orElse: () => null) ??
              errors.first;
        }
      }
    });
  }

  /// Ensure at least [ConcurrencySettings.minWorkers] workers are started
  /// (defaulting to 1 if [ConcurrencySettings.minWorkers] is zero).
  FutureOr<void> start() {
    _stopped = false;
    final needs = _getProvisionNeeds(_queue.isEmpty ? 1 : _queue.length);
    if (needs > 0) {
      return _provisionWorkers(needs);
    }
  }

  void _notify(W worker, {required bool removed}) {
    for (var listener in _workerPoolListeners.values) {
      try {
        listener(worker, removed);
      } catch (ex) {
        // swallow error from user land
      }
    }
  }

  void _removeWorkerAndNotify(PoolWorker<W> poolWorker) {
    _workers.remove(poolWorker);
    _notify(poolWorker.worker, removed: true);
  }

  void _addWorkerAndNotify(PoolWorker<W> poolWorker) {
    _workers.add(poolWorker);
    _notify(poolWorker.worker, removed: false);
  }

  int _removeWorker(PoolWorker<W> poolWorker, bool force) {
    if (force || _workers.length > concurrencySettings.minWorkers) {
      final hashCode = poolWorker.worker.hashCode;
      poolWorker.worker.stop();
      _deadWorkerStats.add(poolWorker.worker.stats.withHashCode(hashCode));
      _removeWorkerAndNotify(poolWorker);
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
      throw SquadronErrorExt.create(
          'the pool cannot accept new requests because it is stopped',
          StackTrace.current);
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

  /// Schedule tasks.
  void _schedule() {
    if (_workers.isEmpty && _startingWorkers > 0) {
      // workers are still starting, defer
      Future(_schedule);
      return;
    }

    // remove dead workers
    _workers
        .where(PoolWorker.isStopped)
        .toList() // take a copy
        .forEach(_removeWorkerAndNotify);

    // remove canceled tasks
    _queue.removeWhere((t) => t.isCanceled);

    // any work to do?
    if (_queue.isEmpty) {
      // no: effectively stop the pool if needed and return
      if (_stopped && _executing.isEmpty) {
        stop();
      }
      return;
    }

    // yes: dispatch tasks to workers
    _dispatchTasks();

    // and provision more workers if possible and necessary
    final needs = _getProvisionNeeds(_queue.length);
    if (needs > 0) {
      _provisionWorkers(needs).then((_) {
        _dispatchTasks();
      }).catchError((ex) {
        logger?.e('provisionning workers failed with error $ex');
        while (_queue.isNotEmpty) {
          _queue.removeFirst().cancel('provisionning workers failed');
        }
      });
    }
  }

  int _sortAndGetMaxCapacity() {
    _workers.sort(PoolWorker.compareCapacityDesc);
    return _workers.isEmpty ? 0 : _workers.first.capacity;
  }

  void _dispatchTasks() {
    int maxCapacity;
    while (_queue.isNotEmpty && (maxCapacity = _sortAndGetMaxCapacity()) > 0) {
      maxCapacity -= 1;
      for (var idx = 0; idx < _workers.length; idx++) {
        final w = _workers[idx];
        if (_queue.isEmpty || w.capacity == 0 || w.capacity < maxCapacity) {
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
  }

  /// Task cancelation. If a specific [task] is provided, only this task will be canceled.
  /// Otherwise, all tasks registered with the [WorkerPool] are canceled.
  void cancel([Task? task, String? message]) {
    if (task != null) {
      _executing.remove(task);
      _queue.removeWhere((t) => t == task);
      task.cancel(message);
    } else {
      final toBeCanceled = _executing.followedBy(_queue).toList();
      _executing.clear();
      _queue.clear();
      for (var task in toBeCanceled) {
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
