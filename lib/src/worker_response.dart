import 'worker_exception.dart';

class WorkerResponse {
  WorkerResponse(this._result)
      : _error = null,
        _stackTrace = null,
        _eos = false;

  WorkerResponse.endOfStream()
      : _result = null,
        _error = null,
        _stackTrace = null,
        _eos = true;

  WorkerResponse.withError(this._error, this._stackTrace)
      : assert(_error != null),
        _result = null,
        _eos = false;

  static const _$result = 'a';
  static const _$error = 'b';
  static const _$stackTrace = 'c';
  static const _$eos = 'd';

  WorkerResponse.deserialize(Map message)
      : _result = message[_$result],
        _error = message[_$error],
        _stackTrace = message[_$stackTrace],
        _eos = message[_$eos] ?? false;

  final String? _error;
  final String? _stackTrace;
  final dynamic _result;
  final bool _eos;

  bool get endOfStream => _eos;

  bool get hasError => _error != null;

  dynamic get result => hasError ? throw exception! : _result;

  String? get error => _error;

  String? get stackTrace => _stackTrace;

  WorkerException? get exception =>
      WorkerException(_error!, stackTrace: _stackTrace);

  @override
  String toString() =>
      'result = $result, error = $error, stackTrace=$stackTrace, endOfStream=$endOfStream';

  Map<String, dynamic> serialize() {
    if (_error != null) return {_$error: _error, _$stackTrace: _stackTrace};
    if (_eos) return {_$eos: true};
    return {_$result: _result};
  }
}
