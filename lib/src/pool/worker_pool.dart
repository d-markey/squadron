import 'dart:async';
import 'dart:collection';

import 'package:logger/web.dart';
import 'package:using/using.dart';

import '../concurrency_settings.dart';
import '../exceptions/exception_manager.dart';
import '../exceptions/squadron_error.dart';
import '../exceptions/squadron_exception.dart';
import '../exceptions/task_terminated_exception.dart';
import '../exceptions/worker_exception.dart';
import '../iworker.dart';
import '../stats/perf_counter.dart';
import '../stats/worker_stat.dart';
import '../typedefs.dart';
import '../worker/worker.dart';
import '../worker_service.dart';
import '_pool_worker.dart';
import '_worker_stream_task.dart';
import '_worker_task.dart';
import '_worker_value_task.dart';
import 'stream_task.dart';
import 'task.dart';
import 'value_task.dart';

typedef WorkerFactory<W> = W Function(ExceptionManager);

/// Worker pool responsible for instantiating, starting and stopping workers running in parallel.
/// A [WorkerPool] is also responsible for creating and assigning [WorkerTask]s to [Worker]s.
abstract class WorkerPool<W extends Worker>
    with Releasable
    implements WorkerService, IWorker {
  /// Create a worker pool.
  ///
  /// Workers are instantiated using the provided [_workerFactory].
  /// The pool will only instantiate workers as needed, depending on [concurrencySettings].
  /// The [ConcurrencySettings.minWorkers] and [ConcurrencySettings.maxWorkers] settings control
  /// how many workers will live in the pool. The [ConcurrencySettings.maxParallel] setting
  /// controls how many tasks can be posted to each individual worker in the pool.
  WorkerPool(this._workerFactory,
      {ConcurrencySettings? concurrencySettings,
      ExceptionManager? exceptionManager})
      : concurrencySettings = concurrencySettings ?? ConcurrencySettings(),
        _exceptionManager = exceptionManager ?? ExceptionManager();

  @override
  void release() {
    stop();
    super.release();
  }

  final WorkerFactory<W> _workerFactory;

  @override
  Logger? channelLogger;

  @override
  ExceptionManager get exceptionManager =>
      (_exceptionManager ??= ExceptionManager());
  ExceptionManager? _exceptionManager;

  /// Concurrency settings.
  final ConcurrencySettings concurrencySettings;

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

  final _workerPoolListeners = <Object, void Function(WorkerStat, bool)>{};

  /// Registers a callback to be invoked when a worker thread is added or removed from the pool.
  Object registerWorkerPoolListener(void Function(WorkerStat, bool) listener) {
    final token = Object();
    _workerPoolListeners[token] = listener;
    return token;
  }

  /// Unregisters a callback.
  void unregisterWorkerPoolListener(
      {Function(WorkerStat, bool)? listener, Object? token}) {
    if (token != null) {
      _workerPoolListeners.remove(token);
    } else if (listener != null) {
      _workerPoolListeners.removeWhere((key, value) => value == listener);
    }
  }

  int _startingWorkers = 0;

  int _getProvisionNeeds(int workload) {
    final minWorkers = concurrencySettings.minWorkers;
    if (workload < minWorkers) {
      // at least minWorkers
      workload = minWorkers;
    }
    final maxWorkers = concurrencySettings.maxWorkers;
    if (maxWorkers > 0 && workload > maxWorkers) {
      // at most maxWorkers if > 0
      workload = maxWorkers;
    }
    // adjust by _workers.length and _startingWorkers
    return workload - _workers.length - _startingWorkers;
  }

  Future<void> _provisionWorkers(int workload) {
    final tasks = <Future>[], errors = [];
    final maxParallel = concurrencySettings.maxParallel;
    for (var i = 0; i < workload; i++) {
      try {
        final worker = _workerFactory(exceptionManager);
        worker.channelLogger = channelLogger;

        final poolWorker = PoolWorker(worker, maxParallel);
        _startingWorkers++;
        tasks.add(poolWorker.worker.start().whenComplete(() {
          _startingWorkers--;
        }).then((_) {
          // start succeeded: register worker
          _addWorkerAndNotify(poolWorker);
        }).catchError((ex, st) {
          // start failed, ensure the worker is stopped
          poolWorker.worker.terminate();
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
          channelLogger?.e(() => 'Error while provisionning workers: $errors');
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
  @override
  FutureOr<void> start() {
    _stopped = false;
    final needs = _getProvisionNeeds(_queue.isEmpty ? 1 : _queue.length);
    if (needs > 0) {
      return _provisionWorkers(needs);
    }
  }

  void _notify(WorkerStat stats, {required bool removed}) {
    if (_workerPoolListeners.isNotEmpty) {
      for (var listener in _workerPoolListeners.values) {
        try {
          listener(stats, removed);
        } catch (ex) {
          // swallow error from user land
        }
      }
    }
  }

  int _removeWorkerAndNotify(PoolWorker<W> poolWorker, bool force) {
    if (force || _workers.length > concurrencySettings.minWorkers) {
      final worker = poolWorker.worker;
      worker.stop();
      if (_workers.remove(poolWorker)) {
        final stats = worker.getStats();
        _deadWorkerStats.add(stats);
        _notify(stats, removed: true);
        return 1;
      }
    }
    return 0;
  }

  void _addWorkerAndNotify(PoolWorker<W> poolWorker) {
    _workers.add(poolWorker);
    _notify(poolWorker.worker.getStats(), removed: false);
  }

  /// Stop idle pool workers matching the [predicate].
  /// If [predicate] is null or not provided, all workers will be stopped.
  /// Stopping a worker does not interrupt or cancel processing. Workers will
  /// complete pending tasks before shutting down. In the meantime, they will
  /// not receive any new workload.
  /// Returns the number of workers that have been stopped.
  @override
  int stop([bool Function(W worker)? predicate]) {
    List<PoolWorker<W>> targets;
    bool force = (predicate == null);
    _workers.sort(PoolWorker.compareCapacity);
    if (force) {
      // kill workers while keeping enough workers alive to process pending tasks
      targets = _workers.reversed.skip(_queue.length).toList();
      _stopped = true;
    } else {
      // kill workers that are idle and satisfy the predicate
      targets = _workers.where((w) => w.isIdle && predicate(w.worker)).toList();
    }
    var stopped = 0;
    for (var poolWorker in targets) {
      stopped += _removeWorkerAndNotify(poolWorker, force);
    }
    return stopped;
  }

  @override
  void terminate([TaskTerminatedException? ex]) {
    _stopped = true;
    for (var i = _workers.length - 1; i >= 0; i--) {
      final w = _workers[i];
      w.worker.terminate(ex);
      _removeWorkerAndNotify(w, true);
    }
  }

  final _queue = Queue<WorkerTask>();
  final _executing = <WorkerTask>{};

  /// Gets remaining workload
  int get pendingWorkload => _queue.length;

  WorkerTask<T, W> _enqueue<T>(WorkerTask<T, W> task) {
    if (_stopped) {
      throw SquadronErrorImpl.create(
        'The pool cannot accept new requests because it is stopped',
      );
    }
    _queue.addLast(task);
    _schedule();
    return task;
  }

  /// Registers and schedules a [task] that returns a single value.
  /// Returns a future that completes with the task's value.
  Future<T> execute<T>(Future<T> Function(W worker) task,
          {PerfCounter? counter}) =>
      scheduleValueTask(task, counter: counter).value;

  /// Registers and schedules a [task] that returns a stream of values.
  /// Returns a stream containing the task's values.
  Stream<T> stream<T>(Stream<T> Function(W worker) task,
          {PerfCounter? counter}) =>
      scheduleStreamTask(task, counter: counter).stream;

  /// Registers and schedules a [task] that returns a single value.
  /// Returns a [ValueTask].
  ValueTask<T> scheduleValueTask<T>(Future<T> Function(W worker) task,
          {PerfCounter? counter}) =>
      _enqueue<T>(WorkerValueTask<T, W>(task, counter)) as ValueTask<T>;

  /// Registers and schedules a [task] that returns a stream of values.
  /// Returns a [StreamTask].
  StreamTask<T> scheduleStreamTask<T>(Stream<T> Function(W worker) task,
          {PerfCounter? counter}) =>
      _enqueue<T>(WorkerStreamTask<T, W>(task, counter)) as StreamTask<T>;

  Timer? _timer;

  void _schedule() {
    if (_timer?.isActive != true) {
      _timer = Timer(Duration.zero, __schedule);
    }
  }

  /// Schedule tasks.
  void __schedule() {
    if (_workers.isEmpty && _startingWorkers > 0) {
      // workers are still starting, defer
      _schedule();
      return;
    }

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
      _provisionWorkers(needs).then(
        (_) => _dispatchTasks(),
        onError: (ex) {
          channelLogger?.e(() => 'Provisionning workers failed with error $ex');
          if (_workers.isEmpty) {
            while (_queue.isNotEmpty) {
              _queue.removeFirst().cancel('Provisionning workers failed');
            }
          } else {
            _schedule();
          }
        },
      );
    }
  }

  void _dispatchTasks() {
    _workers.sort(PoolWorker.compareCapacity);
    for (var idx = _workers.length - 1; idx >= 0; idx--) {
      final w = _workers[idx];
      if (w.isStopped) {
        _removeWorkerAndNotify(w, false);
        continue;
      }
      while (_queue.isNotEmpty && w.capacity > 0) {
        final task = _queue.removeFirst();
        if (!task.isCanceled) {
          _executing.add(task);
          w.run(task).whenComplete(() {
            _executing.remove(task);
            _schedule();
          });
        }
      }
    }
  }

  /// Task cancelation. If a specific [task] is provided, only this task will be canceled.
  /// Otherwise, all tasks registered with the [WorkerPool] are canceled.
  void cancel(Task task, [String? message]) {
    _executing.remove(task);
    _queue.removeWhere((t) => t == task);
    task.cancel(message);
  }

  /// Task cancelation. If a specific [task] is provided, only this task will be canceled.
  /// Otherwise, all tasks registered with the [WorkerPool] are canceled.
  void cancelAll([String? message]) {
    final toBeCanceled = _executing.followedBy(_queue).toList();
    _executing.clear();
    _queue.clear();
    for (var task in toBeCanceled) {
      task.cancel(message);
    }
  }

  /// Worker statistics.
  Iterable<WorkerStat> get stats => _workers.map(PoolWorker.getStats);

  /// Full worker statistics.
  Iterable<WorkerStat> get fullStats => _deadWorkerStats.followedBy(stats);

  /// Worker pools do not need an [operations] map.
  @override
  OperationsMap get operations => WorkerService.noOperations;
}
