import 'package:meta/meta.dart';

import '../_impl/xplat/_helpers.dart';

/// Make [WorkerMessage] a `List` to minimize serialization overhead.
typedef WorkerMessage = List<dynamic>;

extension WorkerMessageImpl on List {
  static const _$traveltime = 0;

  /// [travelTime] is set by the receiving end and measures the time (in
  /// microseconds) it took between the moment the message was serialized and
  /// the moment it was deserialized.
  int? get travelTime => this[_$traveltime];
}

@internal
extension WorkerMessageExt on List {
  static const _$traveltime = WorkerMessageImpl._$traveltime;

  void unwrapTravelTime() {
    final ts = this[_$traveltime];
    if (ts != null) {
      this[_$traveltime] = microsecTimeStamp() - (ts as int);
    }
  }
}
