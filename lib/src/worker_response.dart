import 'dart:async';

import 'squadron.dart';
import 'worker.dart';
import 'squadron_exception.dart';

/// Class used to communicate from a [Worker] to clients.
/// [WorkerResponse]s are used to provide individual results to the client. [Future]-based services simply return a
/// single [WorkerResponse] with the result. [Stream]ing services will return one [WorkerResponse]s for each stream
/// item and mmust send a [WorkerResponse.endOfStream] message to indicate completion. [WorkerResponse]s can also
/// send error messages.
class WorkerResponse {
  WorkerResponse._(dynamic result, this.error, this.endOfStream, this._log)
      : _result =
            (result is Iterable && result is! List) ? result.toList() : result;

  /// [WorkerResponse] with a valid [result]. If [result] is an `Iterable` but not a `List`, it will be converted
  /// to a `List` by calling `toList()`.
  WorkerResponse(dynamic result) : this._(result, null, false, null);

  /// [WorkerResponse] with an error message and an optional (string) [StackTrace].
  WorkerResponse.withError(Object exception, [StackTrace? stackTrace])
      : this._(
            null, SquadronException.from(exception, stackTrace), false, null);

  /// [WorkerResponse] with an error message and an optional (string) [StackTrace].
  WorkerResponse.log(String message) : this._(null, null, false, message);

  /// Special [WorkerResponse] message to indicate the end of a stream.
  WorkerResponse._endOfStream() : this._(null, null, true, null);

  /// End of stream response.
  static final closeStream = WorkerResponse._endOfStream();

  static const _$result = 'a';
  static const _$error = 'b';
  static const _$endOfStream = 'c';
  static const _$timestamp = 'd';
  static const _$log = 'e';

  /// Creates a new [WorkerResponse] from a message sent by the worker.
  static WorkerResponse? deserialize(Map message) {
    final res = WorkerResponse._(
        message[_$result],
        SquadronException.deserialize(message[_$error]),
        message[_$endOfStream] ?? false,
        message[_$log]);
    final ts = message[_$timestamp];
    if (ts != null) {
      res._travelTime = DateTime.now().microsecondsSinceEpoch - (ts as int);
      if (Squadron.debugMode && res._log == null) {
        Squadron.debug('response received in ${res._travelTime} µs');
      }
    }
    if (res._log != null) {
      squadronLog(res._log!);
      return null;
    }
    return res;
  }

  /// [WorkerResponse] serialization.
  Map<String, dynamic> serialize() {
    if (error != null) {
      return {
        _$error: error!.serialize(),
        if (Squadron.debugMode)
          _$timestamp: DateTime.now().microsecondsSinceEpoch,
      };
    } else if (_log != null) {
      return {
        _$log: _log,
        if (Squadron.debugMode)
          _$timestamp: DateTime.now().microsecondsSinceEpoch,
      };
    } else if (endOfStream) {
      return {
        _$endOfStream: true,
        if (Squadron.debugMode)
          _$timestamp: DateTime.now().microsecondsSinceEpoch,
      };
    } else if (_result == null) {
      return {
        if (Squadron.debugMode)
          _$timestamp: DateTime.now().microsecondsSinceEpoch,
      };
    } else {
      return {
        _$result: _result,
        if (Squadron.debugMode)
          _$timestamp: DateTime.now().microsecondsSinceEpoch
      };
    }
  }

  /// Flag indicating the end of the [Stream]ing operation.
  final bool endOfStream;

  /// The [WorkerResponse] exception, if any.
  final SquadronException? error;

  /// Flag indicating whether an error occured.
  bool get hasError => error != null;

  /// When [Squadron.debugMode] is `true`, [travelTime] is set by the receiving end and measures the time
  /// (in microseconds) it took between the moment the message was serialized and the moment it was
  /// deserialized.
  int? get travelTime => _travelTime;
  int? _travelTime;

  final String? _log;

  /// Retrieves the result associated to this [WorkerResponse]. If the [WorkerResponse] contains an error,
  /// an the [error] exception is thrown.
  dynamic get result => hasError ? throw error! : _result;
  final dynamic _result;
}
