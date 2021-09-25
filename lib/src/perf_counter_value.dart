class PerfCounterValue {
  PerfCounterValue(this.name, this.totalTimeInMicroseconds, this.totalCount, this.maxTimeInMicroseconds);

  final String name;
  final int maxTimeInMicroseconds;
  final int totalTimeInMicroseconds;
  final int totalCount;

  @override
  String toString() {
    final average = Duration(microseconds: (totalCount < 1) ? 0 : (totalTimeInMicroseconds ~/ totalCount));
    return '$name: average = $average ($totalCount), max = ${Duration(microseconds: maxTimeInMicroseconds)})';
  }
}
