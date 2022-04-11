import 'dart:convert';

import 'squadron_exception.dart';

/// Squadron Error
class SquadronError extends Error implements SquadronException {
  SquadronError._(this.message) {
    _localStackTrace = super.stackTrace;
  }

  /// Message (or string representation of the exception).
  @override
  final String message;

  static const _$type = 0;
  static const _$message = 1;
  static const _$stackTrace = 2;

  static const _$typeMarker = '\$';

  @override
  List serialize() => [_$typeMarker, message, stackTrace?.toString()];

  late StackTrace? _localStackTrace;
  StackTrace? _remoteStackTrace;

  @override
  StackTrace? get stackTrace => _remoteStackTrace ?? _localStackTrace;

  static SquadronError? deserialize(List data) {
    SquadronError? error;
    if (data[_$type] == _$typeMarker) {
      error = SquadronError._(data[_$message]);
      error._remoteStackTrace =
          SquadronException.loadStackTrace(data[_$stackTrace]);
    }
    return error;
  }

  @override
  String toString() => jsonEncode(serialize());
}

SquadronError newSquadronError(String message) => SquadronError._(message);
