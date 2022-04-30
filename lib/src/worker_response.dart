import 'dart:async';

import 'squadron_exception.dart';

/// Class used to communicate from a [Worker] to clients.
/// [WorkerResponse]s are used to provide individual results to the client. [Future]-based services simply return a
/// single [WorkerResponse] with the result. [Stream]ing services will return one [WorkerResponse]s for each stream
/// item and mmust send a [WorkerResponse.endOfStream] message to indicate completion. [WorkerResponse]s can also
/// send error messages.
class WorkerResponse {
  /// [WorkerResponse] with a valid [result].
  WorkerResponse(dynamic result)
      : _result = result,
        error = null,
        endOfStream = false;

  /// [WorkerResponse] with an error message and an optional (string) [StackTrace].
  WorkerResponse.withError(Object exception, [StackTrace? stackTrace])
      : error = SquadronException.from(
            error: exception, stackTrace: stackTrace ?? StackTrace.current),
        _result = null,
        endOfStream = false;

  /// Special [WorkerResponse] message to indicate the end of a stream.
  const WorkerResponse._endOfStream()
      : _result = null,
        error = null,
        endOfStream = true;

  /// End of stream response.
  static const closeStream = WorkerResponse._endOfStream();

  static const _$result = 'a';
  static const _$error = 'b';
  static const _$endOfStream = 'c';

  /// Creates a new [WorkerResponse] from a message sent by the worker.
  WorkerResponse.deserialize(Map message)
      : _result = message[_$result],
        error = SquadronException.deserialize(message[_$error]),
        endOfStream = message[_$endOfStream] ?? false;

  /// [WorkerResponse] serialization.
  Map<String, dynamic> serialize() {
    if (error != null) {
      return {_$error: error!.serialize()};
    } else if (endOfStream) {
      return const {_$endOfStream: true};
    } else if (_result == null) {
      return const {};
    } else {
      return {_$result: _result};
    }
  }

  /// Flag indicating the end of the [Stream]ing operation.
  final bool endOfStream;

  /// The [WorkerResponse] exception, if any.
  final SquadronException? error;

  /// Flag indicating whether an error occured.
  bool get hasError => error != null;

  /// Retrieves the result associated to this [WorkerResponse]. If the [WorkerResponse] contains an error,
  /// an the [error] exception is thrown.
  dynamic get result => hasError ? throw error! : _result;
  final dynamic _result;
}
