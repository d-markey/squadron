/// Concurrency settings governing parallelization of workers in a [WorkerPool].
class ConcurrencySettings {
  const ConcurrencySettings(
      {this.minWorkers = 0, this.maxWorkers = 0, this.maxParallel = 1})
      : assert(minWorkers >= 0, 'minWorkers must be >= 0'),
        assert(maxWorkers >= 0, 'maxWorkers must be >= 0'),
        assert(minWorkers <= maxWorkers, 'maxWorkers must be >= minWorkers'),
        assert(maxParallel >= 1, 'maxParallel must be >= 1');

  /// Minimum number of workers in the pool.
  final int minWorkers;

  /// Maximum number of workers in the pool. If this is set to 0, the number of
  /// workers is unbounded (as a result, any task posted to the pool will be
  /// assigned a worker asap).
  final int maxWorkers;

  /// Maximum number of tasks that can be posted to a worker. Tasks in excess
  /// will be queued and processed later. Please note that this value does not
  /// reflect real parallelism; eg. when a synchronous workload is picked up by
  /// a worker, it will run to completion (either success or failure) before any
  /// other task can be scheduled.
  final int maxParallel;

  /// Maximum number of running tasks.
  int get maxConcurrency => maxWorkers * maxParallel;

  /// 50 tasks per worker with at most 1 worker.
  static const oneIoThread =
      ConcurrencySettings(minWorkers: 0, maxWorkers: 1, maxParallel: 50);

  /// 50 tasks per worker with at most 2 workers.
  static const twoIoThreads =
      ConcurrencySettings(minWorkers: 0, maxWorkers: 2, maxParallel: 50);

  /// 50 tasks per worker, 1 to 4 workers.
  static const fourIoThreads =
      ConcurrencySettings(minWorkers: 1, maxWorkers: 4, maxParallel: 50);

  /// 50 tasks per worker, 1 to 8 workers.
  static const eightIoThreads =
      ConcurrencySettings(minWorkers: 1, maxWorkers: 8, maxParallel: 50);

  /// 50 tasks per worker, 1 to 16 workers.
  static const sixteenIoThreads =
      ConcurrencySettings(minWorkers: 1, maxWorkers: 16, maxParallel: 50);

  /// 1 task per worker, 1 worker.
  static const oneCpuThread =
      ConcurrencySettings(minWorkers: 1, maxWorkers: 1, maxParallel: 1);

  /// 1 task per worker, 1 to 3 workers.
  static const threeCpuThreads =
      ConcurrencySettings(minWorkers: 1, maxWorkers: 3, maxParallel: 1);

  /// 1 task per worker, 1 to 7 workers.
  static const sevenCpuThreads =
      ConcurrencySettings(minWorkers: 1, maxWorkers: 7, maxParallel: 1);

  /// 1 task per worker, 1 to 15 workers.
  static const fifteenCpuThreads =
      ConcurrencySettings(minWorkers: 1, maxWorkers: 15, maxParallel: 1);
}
