import 'package:cancelation_token/cancelation_token.dart';

import '../worker/worker.dart';
import 'stream_task.dart';
import 'value_task.dart';

/// Base worker task class
abstract class Task<T> {
  /// Flag indicating whether the task is still pending.
  bool get isPending;

  /// Flag indicating whether the task is actually being executed.
  bool get isRunning;

  /// Flag indicating whether the task has completed.
  bool get isFinished;

  /// Flag indicating whether the task has been canceled.
  bool get isCanceled;

  /// Duration between the moment the task was posted, and the moment it was assigned to a [Worker].
  Duration get waitTime;

  /// Duration between the moment the task was assigned to a [Worker], and the moment it finished executing.
  Duration get runningTime;

  /// Cancels the task. If the task is still pending, cancelation is effective immediately with a
  /// [CanceledException]. For a running [ValueTask], cancelation is ignored and the task's [ValueTask.value]
  /// will eventually complete. For a running [StreamTask], cancelation will be effective after receiving the
  /// next value and the task's [StreamTask.stream] will be closed. It should be noted that cancelation of
  /// running tasks will not be notified to platform workers. To give running tasks a chance to get notified
  /// of cancelation, a [CancelationToken] should be passed on to tasks at the time they are created.
  void cancel([String? message]);
}
