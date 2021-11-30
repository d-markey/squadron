import 'dart:async';

import 'cancellable_token.dart';
import 'squadron_exception.dart';
import 'worker_exception.dart';

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

  Timer? _timer;

  /// Called just before processing a [WorkerRequest]. The [onTimeout] callback may not be null, and a timer will be
  /// started that will automatically cancel this token if processing takes longer than [duration].
  @override
  void start() => _timer ??= Timer(
      duration,
      () => super.setException(
          TaskTimeoutException(message: message, duration: duration)));
}
