import '../_impl/xplat/_time_stamp.dart';

extension type StreamId._(int handle) {
  static int _nextId = 1;

  factory StreamId.next() => StreamId._(_nextId++);

  static StreamId? from(dynamic value) =>
      (value is num) ? StreamId._(value.toInt()) : null;
}

/// Make [WorkerMessage] a `List` to minimize serialization overhead.
extension type WorkerMessage(List data) implements Object {
  /// [travelTime] is set by the receiving end and measures the time (in
  /// microseconds) it took between the moment the message was serialized and
  /// the moment it was deserialized.
  int? get travelTime => data[_$traveltime];

  void unwrapTravelTime() {
    final ts = Timestamp.from(data[_$traveltime]);
    if (ts != null) {
      data[_$traveltime] = Timestamp.now() - ts;
    }
  }
}

const _$traveltime = 0;
