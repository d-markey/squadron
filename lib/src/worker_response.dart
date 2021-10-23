import 'worker_exception.dart';
import 'worker.dart';

/// Class used to communicate from a [Worker] to clients.
/// [WorkerResponse]s are used to provide individual results to the client. [Future]-based services simply return a
/// single [WorkerResponse] with the result. [Stream]ing services will return one [WorkerResponse]s for each stream
/// item and mmust send a [WorkerResponse.endOfStream] message to indicate completion. [WorkerResponse]s can also
/// send error messages.
class WorkerResponse {
  /// [WorkerResponse] with a valid [result].
  WorkerResponse(this._result)
      : _error = null,
        _stackTrace = null,
        _eos = false;

  /// Special [WorkerResponse] message to indicate the end of the stream.
  WorkerResponse.endOfStream()
      : _result = null,
        _error = null,
        _stackTrace = null,
        _eos = true;

  /// [WorkerResponse] with an error message and an optional (string) [StackTrace].
  WorkerResponse.withError(this._error, [String? stackTrace])
      : assert(_error != null),
        _stackTrace = stackTrace,
        _result = null,
        _eos = false;

  static const _$result = 'a';
  static const _$error = 'b';
  static const _$stackTrace = 'c';
  static const _$eos = 'd';

  /// Creates a new [WorkerResponse] from a message sent by the worker.
  WorkerResponse.deserialize(Map message)
      : _result = message[_$result],
        _error = message[_$error],
        _stackTrace = message[_$stackTrace],
        _eos = message[_$eos] ?? false;

  final String? _error;
  final String? _stackTrace;
  final dynamic _result;
  final bool _eos;

  /// Flag indicating the end of the [Stream]ing operation.
  bool get endOfStream => _eos;

  /// Flag indicating whether an error occured.
  bool get hasError => _error != null;

  /// Retrieves the result associated to this [WorkerResponse]. If the [WorkerResponse] contains an error,
  /// an [exception] is thrown.
  dynamic get result => hasError ? throw exception! : _result;

  /// The [WorkerResponse] error message, if any.
  String? get error => _error;

  /// The [WorkerResponse] stackTrace information as [String], if any.
  String? get stackTrace => _stackTrace;

  /// The [WorkerResponse] stackTrace information as [String], if any.
  WorkerException? get exception =>
      hasError ? WorkerException(_error!, stackTrace: _stackTrace) : null;

  @override
  String toString() =>
      'result = $result, error = $error, stackTrace=$stackTrace, endOfStream=$endOfStream';

  /// [WorkerResponse] serialization.
  Map<String, dynamic> serialize() {
    if (_error != null) return {_$error: _error, _$stackTrace: _stackTrace};
    if (_eos) return {_$eos: true};
    return {_$result: _result};
  }
}
