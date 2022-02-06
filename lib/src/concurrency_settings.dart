/// Concurrency settings governing parallelization of workers in a [WorkerPool].
class ConcurrencySettings {
  const ConcurrencySettings(
      {this.minWorkers = 0, this.maxWorkers = 0, this.maxParallel = 1})
      : assert(minWorkers >= 0),
        assert(maxWorkers >= 0),
        assert(minWorkers <= maxWorkers),
        assert(maxParallel >= 1);

  /// Minimum number of workers in the pool.
  final int minWorkers;

  /// Maximum number of workers in the pool.
  /// If this is set to 0, the number of workers is unbounded (as a result, any task posted to the pool will be assigned a worker asap).
  final int maxWorkers;

  /// Maximum number of tasks that can be posted to a worker.
  final int maxParallel;

  /// Returns the number of workers necessary to handle [pending] tasks, taking into account [minWorkers] and [maxWorkers].
  int max(int pending) {
    if (pending < minWorkers) return minWorkers;
    if (pending < maxWorkers || maxWorkers == 0) return pending;
    return maxWorkers;
  }

  /// Returns the number of workers necessary to have at least [minLive] live workers, taking into account [minWorkers] and [maxWorkers].
  int min(int minLive) {
    if (minLive < minWorkers) return minWorkers;
    return max(minLive);
  }

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

  /// 1 task per worker, 1 to 3 workers.
  static const threeCpuThreads =
      ConcurrencySettings(minWorkers: 1, maxWorkers: 3, maxParallel: 1);

  /// 1 tasks per worker, 1 to 7 workers.
  static const sevenCpuThreads =
      ConcurrencySettings(minWorkers: 1, maxWorkers: 7, maxParallel: 1);

  /// 1 task per worker, unbounded number of workers.
  static const manyCpuThreads =
      ConcurrencySettings(minWorkers: 0, maxWorkers: 0, maxParallel: 1);
}
