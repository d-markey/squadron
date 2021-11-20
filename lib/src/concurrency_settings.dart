class ConcurrencySettings {
  const ConcurrencySettings(
      {this.minWorkers = 0, this.maxWorkers = 0, this.maxParallel = 1})
      : assert(minWorkers >= 0),
        assert(maxWorkers >= 0),
        assert(minWorkers <= maxWorkers),
        assert(maxParallel >= 1);

  final int minWorkers;
  final int maxWorkers;
  final int maxParallel;

  int max(int pending) {
    if (pending < minWorkers) return minWorkers;
    if (pending < maxWorkers || maxWorkers == 0) return pending;
    return maxWorkers;
  }

  int min(int minLive) {
    if (minLive < minWorkers) return minWorkers;
    return max(minLive);
  }

  static const manyCpuThreads =
      ConcurrencySettings(minWorkers: 0, maxWorkers: 0, maxParallel: 1);
  static const oneIoThread =
      ConcurrencySettings(minWorkers: 0, maxWorkers: 1, maxParallel: 50);
  static const fourCpuThreads =
      ConcurrencySettings(minWorkers: 1, maxWorkers: 4, maxParallel: 1);
  static const fourIoThreads =
      ConcurrencySettings(minWorkers: 1, maxWorkers: 4, maxParallel: 50);
  static const eightCpuThreads =
      ConcurrencySettings(minWorkers: 1, maxWorkers: 8, maxParallel: 1);
  static const eightIoThreads =
      ConcurrencySettings(minWorkers: 1, maxWorkers: 8, maxParallel: 50);
}
