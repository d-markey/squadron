import 'dart:async';

import 'task.dart';

/// Class representing a [Task] returning a stream of values.
abstract class StreamTask<T> extends Task<T> {
  /// The task's stream.
  Stream<T> get stream;
}
