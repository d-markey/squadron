import 'dart:async';

import 'perf_counter_value.dart';

class PerfCounter {
  PerfCounter(this.name);

  final String name;
  int _maxTimeInMicroseconds = 0;
  int _totalTimeInMicroseconds = 0;
  int _totalCount = 0;

  int get maxTimeInMicroseconds => _maxTimeInMicroseconds;
  int get totalTimeInMicroseconds => _totalTimeInMicroseconds;
  int get totalCount => _totalCount;

  @override
  String toString() {
    final average = Duration(microseconds: (totalCount == 0) ? 0 : (totalTimeInMicroseconds ~/ totalCount));
    return '$name: average = $average ($totalCount), max = ${Duration(microseconds: maxTimeInMicroseconds)})';
  }

  void update(int timeInMicroseconds) {
    if (timeInMicroseconds > _maxTimeInMicroseconds) _maxTimeInMicroseconds = timeInMicroseconds;
    _totalTimeInMicroseconds += timeInMicroseconds;
    _totalCount++;
  }

  Future<T> measure<T>(Future<T> Function() task) {
    var ts = DateTime.now().microsecondsSinceEpoch;
    return task().whenComplete(() {
      update(DateTime.now().microsecondsSinceEpoch - ts);
    });
  }

  PerfCounterValue get value => PerfCounterValue(name, _totalTimeInMicroseconds, _totalCount, _maxTimeInMicroseconds);
}
