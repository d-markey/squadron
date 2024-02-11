import 'package:meta/meta.dart';

import '_well_known_exceptions.dart';
import 'squadron_exception.dart';

/// Exception to keep track of errors encountered in a worker.
class WorkerException extends SquadronException {
  /// Creates a new [WorkerException] to capture error context.
  WorkerException(this.message,
      {StackTrace? stackTrace, String? workerId, int? command})
      : _stackTrace = stackTrace,
        _workerId = workerId,
        _command = command {
    if (_stackTrace == null) {
      try {
        _stackTrace = StackTrace.current;
      } catch (_) {
        // ignore...
      }
    }
  }

  static const _$type = 0;
  static const _$message = 1;
  static const _$stackTrace = 2;
  static const _$workerId = 3;
  static const _$command = 4;

  @override
  List serialize() => List.unmodifiable([
        $workerExceptionType,
        message,
        _stackTrace?.toString(),
        _workerId,
        _command,
      ]);

  static WorkerException? deserialize(List data) =>
      (data[_$type] == $workerExceptionType)
          ? WorkerException(data[_$message],
              stackTrace: SquadronException.loadStackTrace(data[_$stackTrace]),
              workerId: data[_$workerId],
              command: data[_$command])
          : null;

  /// Message.
  @override
  final String message;

  /// Stack trace associated to the original exception.
  @override
  StackTrace? get stackTrace => _stackTrace;
  StackTrace? _stackTrace;

  /// Worker ID.
  String? get workerId => _workerId;
  String? _workerId;

  /// Command.
  int? get command => _command;
  int? _command;
}

@internal
extension WorkerExceptionExt on WorkerException {
  void withWorkerId(String? workerId) {
    _workerId ??= workerId;
  }

  void withCommand(int? command) {
    _command ??= command;
  }

  void withStackTrace(StackTrace? stackTrace) {
    _stackTrace ??= stackTrace;
  }
}
