extension type Timestamp._(int _microseconds) {
  factory Timestamp.now() => Timestamp._(DateTime.now().microsecondsSinceEpoch);

  static Timestamp? from(dynamic value) => (value is num)
      ? Timestamp._(value.toInt())
      : ((value is DateTime)
          ? Timestamp._(value.microsecondsSinceEpoch)
          : null);

  int operator -(Timestamp other) => _microseconds - other._microseconds;

  Duration elapsedSince(Timestamp other) =>
      Duration(microseconds: this - other);

  DateTime toDateTime() => DateTime.fromMicrosecondsSinceEpoch(_microseconds);
}
