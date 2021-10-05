import 'dart:async';

import 'perf_counter_snapshot.dart';

/// Simple performance counter to consolidate statistics about [Future] completion: total number of calls, total elapsed time, and max elapsed time.
class PerfCounter implements PerfCounterSnapshot {
  /// Creates a performance counter
  PerfCounter(this.name)
      : _maxTimeInMicroseconds = 0,
        _totalTimeInMicroseconds = 0,
        _totalCount = 0,
        _totalErrors = 0;

  /// The counter's name or label
  @override
  final String name;

  /// Maximum elapsed time for a single call, in microseconds
  @override
  int get maxTimeInMicroseconds => _maxTimeInMicroseconds;
  int _maxTimeInMicroseconds;

  /// Total elapsed time, in microseconds
  @override
  int get totalTimeInMicroseconds => _totalTimeInMicroseconds;
  int _totalTimeInMicroseconds;

  /// Total number of calls
  @override
  int get totalCount => _totalCount;
  int _totalCount;

  /// Total number of errors
  @override
  int get totalErrors => _totalErrors;
  int _totalErrors;

  /// Updates counter value with the duration indicated by [timeInMicroseconds]
  /// * update the maximum elapsed time if required
  /// * add specified time to the total elapsed time
  /// * increment the total number of calls by 1
  void update(int timeInMicroseconds) {
    if (timeInMicroseconds > _maxTimeInMicroseconds) {
      _maxTimeInMicroseconds = timeInMicroseconds;
    }
    _totalTimeInMicroseconds += timeInMicroseconds;
    _totalCount++;
  }

  /// Returns a [Future] that will measure the elapsed time to completion of the specified [task]
  Future<T> measure<T>(Future<T> Function() task) => Future(() async {
        var ts = DateTime.now().microsecondsSinceEpoch;
        try {
          return await task();
        } catch (e) {
          _totalErrors += 1;
          rethrow;
        } finally {
          update(DateTime.now().microsecondsSinceEpoch - ts);
        }
      });

  /// Returns a snapshot of the [counter]'s values
  PerfCounterSnapshot get value => PerfCounterSnapshot(this);
}
