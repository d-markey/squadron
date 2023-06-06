import '../squadron.dart';
import '../worker_service.dart';

void safeInvoke(SquadronCallback? callback) {
  try {
    if (callback != null) {
      callback();
    }
  } catch (e) {
    Squadron.warning('callback $callback failed: $e');
  }
}

final _sqEpoch = DateTime.utc(2020, 1, 1);

int microsecTimeStamp() =>
    DateTime.timestamp().difference(_sqEpoch).inMicroseconds;
