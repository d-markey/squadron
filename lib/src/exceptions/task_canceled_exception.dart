import 'dart:convert';

import 'package:cancelation_token/cancelation_token.dart';

import 'squadron_error.dart';

class TaskCanceledException implements SquadronError, CanceledException {
  TaskCanceledException(String? message) : message = message ?? 'Task canceled';

  @override
  final String message;

  @override
  StackTrace? get stackTrace => null;

  @override
  String toString() => '$runtimeType: ${jsonEncode(serialize())}';

  @override
  List serialize() => throw UnimplementedError();
}
