import 'dart:convert';

import 'package:cancelation_token/cancelation_token.dart';
import 'package:meta/meta.dart';

import '_builtin_exceptions.dart';
import 'squadron_error.dart';
import 'squadron_exception.dart';

class TaskTerminatedException implements SquadronError, CanceledException {
  TaskTerminatedException(this.message, [this.stackTrace]);

  @override
  final String message;

  @override
  final StackTrace? stackTrace;

  @override
  String toString() => jsonEncode(serialize());

  @override
  List serialize() => List.unmodifiable(
      [$taskTerminatedExceptionType, message, stackTrace?.toString()]);
}

const _$type = 0;
const _$message = 1;
const _$stackTrace = 2;

@internal
extension TaskTerminatedExceptionExt on TaskTerminatedException {
  static TaskTerminatedException? deserialize(List? props) {
    if (props == null) return null;
    if (props[_$type] != $taskTerminatedExceptionType) return null;
    return TaskTerminatedException(
      props[_$message],
      SquadronException.loadStackTrace(props[_$stackTrace]),
    );
  }
}
