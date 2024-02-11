import 'dart:async';

import '../_impl/xplat/_task.dart';

/// Class representing a [Task] returning a single value.
abstract class ValueTask<T> extends Task<T> {
  /// The task's value provided as a [Future].
  Future<T> get value;
}
