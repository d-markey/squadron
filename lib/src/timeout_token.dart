import 'dart:async';

import 'cancellable_token.dart';
import 'squadron_exception.dart';
import 'worker_service.dart';

/// Time-out cancellation tokens used by callers of worker services. The token is cancelled automatically after
/// a period of time indicated by [duration] with a countdown starting only when the task is assigned to a
/// platform worker.
class TimeOutToken extends CancellableToken {
  TimeOutToken(this.duration, [String? message]) : super(message);

  /// Throws an exception, time-out tokens may not be cancelled programmatically.
  @override
  void cancel() => throw SquadronException(
      'A $runtimeType cannot be cancelled programmatically.');

  /// Duration of the timeout. The timer is not started before task is scheduled on a platform worker.
  final Duration duration;

  SquadronCallback? _onTimeout;
  Timer? _timer;

  /// Used to execute the time-out callback, then notify listeners that have been registered with [addListener],
  /// that the token has been cancelled.
  @override
  void notifyListeners() {
    safeInvoke(_onTimeout);
    super.notifyListeners();
  }

  /// Called just before processing a [WorkerRequest]. The [onTimeout] callback may not be null, and a timer will be
  /// started that will automatically cancel this token if processing takes longer than [duration].
  @override
  void start({SquadronCallback? onTimeout}) {
    assert(onTimeout != null);
    stop();
    _onTimeout = onTimeout;
    _timer ??= Timer(duration, super.cancel);
  }

  /// Called just after processing a [WorkerRequest]. Will cancel the timer to prevent execution of the timeout
  /// callback.
  @override
  void stop() {
    if (_timer != null) {
      _timer!.cancel();
      _onTimeout = null;
      _timer = null;
    }
  }
}
