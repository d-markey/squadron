import 'package:meta/meta.dart';

import '_builtin_exceptions.dart';
import 'squadron_exception.dart';

/// Squadron Error
class SquadronError extends SquadronException {
  SquadronError._(super.message, [super.stackTrace]) : super.init();

  @override
  List serialize() => List.unmodifiable([
        $squadronErrorType,
        message,
        stackTrace?.toString(),
      ]);
}

const _$type = 0;
const _$message = 1;
const _$stackTrace = 2;

@internal
extension SquadronErrorExt on SquadronError {
  static SquadronError create(String message, [StackTrace? stackTrace]) =>
      SquadronError._(message, stackTrace);

  static SquadronException? deserialize(List exceptionInfo) =>
      (exceptionInfo[_$type] == $squadronErrorType)
          ? SquadronError._(
              exceptionInfo[_$message],
              SquadronException.loadStackTrace(exceptionInfo[_$stackTrace]),
            )
          : null;
}
