import 'perf_counter.dart';

/// A snapshot of a [PerfCounter]'s values
class PerfCounterSnapshot {
  /// Creates a new snapshop from a the specified [counter]
  PerfCounterSnapshot(PerfCounter counter)
      : name = counter.name,
        maxTimeInMicroseconds = counter.maxTimeInMicroseconds,
        totalTimeInMicroseconds = counter.totalTimeInMicroseconds,
        totalCount = counter.totalCount;

  /// The counter's name or label
  final String name;

  /// Maximum elapsed time for a single call (in microseconds)
  final int maxTimeInMicroseconds;

  /// Total elapsed time (in microseconds)
  final int totalTimeInMicroseconds;

  /// Total number of calls
  final int totalCount;

  @override
  String toString() {
    final average = Duration(
        microseconds:
            (totalCount < 1) ? 0 : (totalTimeInMicroseconds ~/ totalCount));
    return '$name: average = $average ($totalCount), max = ${Duration(microseconds: maxTimeInMicroseconds)})';
  }
}
