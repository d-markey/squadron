import 'dart:async';

import 'cancellation_token.dart';
import 'worker.dart';
import 'worker_exception.dart';

/// Base worker task class
abstract class Task<T> {
  /// Flag indicating whether the task is actually being executed.
  bool get isRunning;

  /// Flag indicating whether the task has completed.
  bool get isFinished;

  /// Flag indicating whether the task has been cancelled.
  bool get isCancelled;

  /// Duration between the moment the task was posted, and the moment it was assigned to a [Worker].
  Duration get waitTime;

  /// Duration between the moment the task was assigned to a [Worker], and the moment it finished executing.
  Duration get runningTime;

  /// Cancels the task. If the task is still pending, cancellation is effective immediately with a
  /// [CancelledException]. For a running [ValueTask], cancellation is ignored and the task's [ValueTask.value]
  /// will eventually complete. For a running [StreamTask], cancellation will be effective after receiving the
  /// next value and the task's [StreamTask.stream] will be closed. It should be noted that cancellation of
  /// running tasks will not be notified to platform workers. To give running tasks a chance to get notified
  /// of cancellation, a [CancellationToken] should be passed on to tasks at the time they are created.
  void cancel([String? message]);
}

/// Class representing a [Task] returning a single value.
abstract class ValueTask<T> extends Task<T> {
  /// The task's value provided as a [Future].
  Future<T> get value;
}

/// Class representing a [Task] returning a stream of values.
abstract class StreamTask<T> extends Task<T> {
  /// The task's stream.
  Stream<T> get stream;
}
