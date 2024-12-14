import 'dart:convert';

import 'package:cancelation_token/cancelation_token.dart';
import 'package:meta/meta.dart';

import '_builtin_exceptions.dart';
import 'squadron_error.dart';

class TaskCanceledException implements SquadronError, CanceledException {
  TaskCanceledException(String? message) : message = message ?? 'Task canceled';

  @override
  final String message;

  @override
  StackTrace? get stackTrace => null;

  @override
  String toString() => jsonEncode(serialize());

  @override
  List serialize() => List.unmodifiable([$taskCanceledExceptionType, message]);
}

const _$type = 0;
const _$message = 1;

@internal
extension TaskCanceledExceptionExt on TaskCanceledException {
  static TaskCanceledException? deserialize(List? props) {
    if (props == null) return null;
    if (props[_$type] != $taskCanceledExceptionType) return null;
    return TaskCanceledException(props[_$message]);
  }
}
