import 'package:meta/meta.dart';

import '_well_known_exceptions.dart';
import 'squadron_exception.dart';

/// Exception to keep track of errors encountered in a worker.
class WorkerException extends SquadronException {
  /// Creates a new [WorkerException] to capture error context.
  WorkerException(String message, {StackTrace? stackTrace, int? command})
      : _command = command,
        super.init(message, stackTrace);

  @override
  List serialize() => List.unmodifiable([
        $workerExceptionType,
        message,
        stackTrace?.toString(),
        _command,
      ]);

  /// Command.
  int? get command => _command;
  int? _command;
}

const _$type = 0;
const _$message = 1;
const _$stackTrace = 2;
const _$command = 3;

@internal
extension WorkerExceptionExt on WorkerException {
  void withCommand(int? command) {
    _command ??= command;
  }

  void withStackTrace(StackTrace? stackTrace) {
    if (stackTrace != null) {
      forceStackTrace(stackTrace);
    }
  }

  static WorkerException? deserialize(List data) =>
      (data[_$type] == $workerExceptionType)
          ? WorkerException(
              data[_$message],
              stackTrace: SquadronException.loadStackTrace(data[_$stackTrace]),
              command: data[_$command],
            )
          : null;
}
