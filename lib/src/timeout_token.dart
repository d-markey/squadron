import 'dart:async';

import 'cancellation_token.dart';
import 'squadron_error.dart';
import 'worker_exception.dart';

/// Time-out cancellation tokens used by callers of worker services. The token is cancelled automatically after
/// a period of time indicated by [duration] with a countdown starting only when the task is assigned to a
/// platform worker.
class TimeOutToken extends CancellationToken {
  TimeOutToken(this.duration, [String message = 'The token timed out'])
      : super(message);

  /// Duration of the timeout. The timer is not started before task is scheduled on a platform worker.
  final Duration duration;

  Timer? _timer;

  /// Throws an exception, time-out tokens may not be cancelled programmatically.
  @override
  void cancel([CancelledException? exception]) => throw newSquadronError(
      'TimeOutToken cannot be cancelled programmatically');

  /// Called just before processing a [WorkerRequest]. The [onTimeout] callback may not be null, and a timer will be
  /// started that will automatically cancel this token if processing takes longer than [duration].
  @override
  void ensureStarted() => _timer ??= Timer(duration, () {
        super
            .cancel(TaskTimeoutException(message: message, duration: duration));
      });

  /// Returns `true` if the timeout has started, `false` otherwise.
  bool get started => _timer != null;
}
