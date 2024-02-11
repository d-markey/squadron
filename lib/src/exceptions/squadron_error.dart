import 'dart:convert';

import 'package:meta/meta.dart';

import '../squadron.dart';
import '_well_known_exceptions.dart';
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

  @override
  List serialize() => List.unmodifiable([
        $squadronErrorType,
        message,
        _stackTrace?.toString(),
      ]);

  @override
  StackTrace? get stackTrace => _stackTrace;
  StackTrace? _stackTrace;

  @override
  String toString() => jsonEncode(serialize());
}

@internal
extension SquadronErrorExt on SquadronError {
  static SquadronError create(String message, StackTrace stackTrace) {
    Squadron.severe('SquadronError: $message');
    return SquadronError._(message, stackTrace);
  }

  static SquadronException? deserialize(List exceptionInfo) =>
      (exceptionInfo[SquadronError._$type] == $squadronErrorType)
          ? SquadronError._(
              exceptionInfo[SquadronError._$message],
              SquadronException.loadStackTrace(
                  exceptionInfo[SquadronError._$stackTrace]))
          : null;
}
