import 'perf_counter_snapshot.dart';

/// Simple performance counter to consolidate statistics about woker tast execution: total number of calls, total
/// number of errors, total elapsed time, and max elapsed time.
class PerfCounter implements PerfCounterSnapshot {
  /// Creates a performance counter.
  PerfCounter(this.name)
      : _maxTimeInMicroseconds = 0,
        _totalTimeInMicroseconds = 0,
        _totalCount = 0,
        _totalErrors = 0;

  /// The counter's name or label.
  @override
  final String name;

  /// Maximum elapsed time for a single call, in microseconds.
  @override
  int get maxTimeInMicroseconds => _maxTimeInMicroseconds;
  int _maxTimeInMicroseconds;

  /// Total elapsed time, in microseconds.
  @override
  int get totalTimeInMicroseconds => _totalTimeInMicroseconds;
  int _totalTimeInMicroseconds;

  /// Total number of calls.
  @override
  int get totalCount => _totalCount;
  int _totalCount;

  /// Total number of errors.
  @override
  int get totalErrors => _totalErrors;
  int _totalErrors;

  /// Returns a snapshot of the [PerfCounter]'s values.
  PerfCounterSnapshot get snapshot => PerfCounterSnapshot(this);
}

// for internal use
extension PerfCounterExt on PerfCounter {
  /// Updates counter value with the duration indicated by [timeInMicroseconds].
  /// 1. update the maximum elapsed time if required.
  /// 2. add specified time to the total elapsed time.
  /// 3. depending on [success], increment the total number of calls or errors by 1.
  void update(int timeInMicroseconds, bool success) {
    if (timeInMicroseconds > _maxTimeInMicroseconds) {
      _maxTimeInMicroseconds = timeInMicroseconds;
    }
    _totalTimeInMicroseconds += timeInMicroseconds;
    if (success) {
      _totalCount++;
    } else {
      _totalErrors++;
    }
  }
}
