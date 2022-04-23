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
