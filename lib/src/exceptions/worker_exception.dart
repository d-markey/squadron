import 'package:meta/meta.dart';

import '_well_known_exceptions.dart';
import 'squadron_exception.dart';

/// Exception to keep track of errors encountered in a worker.
class WorkerException extends SquadronException {
  /// Creates a new [WorkerException] to capture error context.
  WorkerException(this.message, {StackTrace? stackTrace, int? command})
      : _stackTrace = stackTrace,
        _command = command {
    if (_stackTrace == null) {
      try {
        // _stackTrace = _getCurrentStackTrace();
        _stackTrace = StackTrace.current;
      } catch (_, st) {
        // failed, get stack trace from this exception!
        _stackTrace = st;
      }
    }
  }

  static StackTrace? _getCurrentStackTrace() {
    StackTrace? stackTrace;
    try {
      throw '';
    } catch (_, st) {
      stackTrace = st;
    }
    return stackTrace;
  }

  static const _$type = 0;
  static const _$message = 1;
  static const _$stackTrace = 2;
  static const _$command = 3;

  @override
  List serialize() => List.unmodifiable([
        $workerExceptionType,
        message,
        _stackTrace?.toString(),
        _command,
      ]);

  static WorkerException? deserialize(List data) =>
      (data[_$type] == $workerExceptionType)
          ? WorkerException(data[_$message],
              stackTrace: SquadronException.loadStackTrace(data[_$stackTrace]),
              command: data[_$command])
          : null;

  /// Message.
  @override
  final String message;

  /// Stack trace associated to the original exception.
  @override
  StackTrace? get stackTrace => _stackTrace;
  StackTrace? _stackTrace;

  /// Command.
  int? get command => _command;
  int? _command;
}

@internal
extension WorkerExceptionExt on WorkerException {
  void withCommand(int? command) {
    _command ??= command;
  }

  void withStackTrace(StackTrace? stackTrace) {
    _stackTrace ??= stackTrace;
  }
}
