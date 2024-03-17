import 'dart:async';

import 'task.dart';

/// Class representing a [Task] returning a single value.
abstract class ValueTask<T> extends Task<T> {
  /// The task's value provided as a [Future].
  Future<T> get value;
}
