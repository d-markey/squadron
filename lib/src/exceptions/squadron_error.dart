import 'package:meta/meta.dart';

import '_builtin_exceptions.dart';
import 'squadron_exception.dart';

/// Squadron Error
class SquadronError extends SquadronException {
  SquadronError._(super.message, [super.stackTrace, int? command])
      : _command = command,
        super.init();

  final int? _command;

  @override
  List serialize() => List.unmodifiable([
        $squadronErrorType,
        message,
        stackTrace?.toString(),
        _command,
      ]);
}

const _$type = 0;
const _$message = 1;
const _$stackTrace = 2;
const _$command = 3;

@internal
extension SquadronErrorExt on SquadronError {
  static SquadronError create(String message,
          [StackTrace? stackTrace, int? command]) =>
      SquadronError._(message, stackTrace, command);

  static SquadronException? deserialize(List exceptionInfo) =>
      (exceptionInfo[_$type] == $squadronErrorType)
          ? SquadronError._(
              exceptionInfo[_$message],
              SquadronException.loadStackTrace(exceptionInfo[_$stackTrace]),
              exceptionInfo[_$command],
            )
          : null;
}
