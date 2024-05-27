import 'package:meta/meta.dart';

import '../_impl/xplat/_helpers.dart';
import '../typedefs.dart';

/// Make [WorkerMessage] a `List` to minimize serialization overhead.
extension type WorkerMessage(List data) {
  /// [travelTime] is set by the receiving end and measures the time (in
  /// microseconds) it took between the moment the message was serialized and
  /// the moment it was deserialized.
  int? get travelTime => data[_$traveltime];
}

const _$traveltime = 0;

@internal
extension WorkerMessageExt on WorkerMessage {
  void unwrapTravelTime() {
    dbgTrace('   unwrap travel time ${data[_$traveltime]}...');
    final ts = data[_$traveltime];
    if (ts != null) {
      data[_$traveltime] = microsecTimeStamp() - (ts as num).toInt();
    }
  }
}
