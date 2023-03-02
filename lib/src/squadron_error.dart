import 'dart:convert';

import 'package:meta/meta.dart';

import 'squadron.dart';
import 'squadron_exception.dart';

/// Squadron Error
class SquadronError implements SquadronException {
  SquadronError._(this.message, [this._stackTrace]) {
    if (_stackTrace == null) {
      try {
        _stackTrace = StackTrace.current;
      } catch (_) {
        // ignore...
      }
    }
  }

  /// Message (or string representation of the exception).
  @override
  final String message;

  static const _$type = 0;
  static const _$message = 1;
  static const _$stackTrace = 2;

  static const _$typeMarker = '\$';

  @override
  List serialize() => [_$typeMarker, message, _stackTrace?.toString()];

  @override
  StackTrace? get stackTrace => _stackTrace;
  StackTrace? _stackTrace;

  @override
  String toString() => jsonEncode(serialize());
}

@internal
SquadronError newSquadronError(String message) {
  Squadron.severe('creating new SquadronError: $message');
  return SquadronError._(message);
}

@internal
SquadronError? deserializeSquadronError(List data) {
  SquadronError? error;
  if (data[SquadronError._$type] == SquadronError._$typeMarker) {
    error = SquadronError._(data[SquadronError._$message],
        SquadronException.loadStackTrace(data[SquadronError._$stackTrace]));
  }
  return error;
}
