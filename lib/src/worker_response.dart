import 'package:squadron/squadron.dart';

class WorkerResponse {
  WorkerResponse([this._result])
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

  WorkerResponse.fromMessage(Map<String, dynamic> message)
      : _result = message[''],
        _error = message['!'],
        _stackTrace = message['?'],
        _eos = message['#'] ?? false;

  final String? _error;
  final String? _stackTrace;
  final dynamic _result;
  final bool _eos;

  dynamic get result {
    if (_error != null) {
      throw WorkerException(_error!, stackTrace: _stackTrace);
    }
    return _result;
  }

  bool get endOfStream => _eos;

  Map<String, dynamic> serialize() {
    if (_error != null) return {'!': _error, '?': _stackTrace};
    if (_eos) return {'#': true};
    return {'': _result};
  }
}
