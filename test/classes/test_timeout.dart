import 'dart:async';

import 'test_exception.dart';

class TestTimeout {
  TestTimeout(this.duration, {this.onTimeout});

  final Duration duration;
  final void Function(TestTimeout)? onTimeout;

  bool _cancelled = false;
  Timer? _timer;
  final _completer = Completer<void>();

  void cancel() {
    _completer.future.ignore();
    _cancelled = true;
    _timer?.cancel();
    _timer = null;
  }

  // a cancelled timeout never completes
  Future<void> get completion {
    if (_timer == null && !_cancelled) {
      _timer = Timer(duration, () {
        if (!_cancelled && !_completer.isCompleted) {
          _completer.completeError(TestTimeOutException());
        }
      });
    }
    return _completer.future;
  }
}
