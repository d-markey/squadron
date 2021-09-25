class WorkerResponse {
  WorkerResponse([this.result]) : error = null, stackTrace = null, _eos = false;

  WorkerResponse.endOfStream() : result = null, error = null, stackTrace = null, _eos = true;

  WorkerResponse.withError(this.error, this.stackTrace) : assert(error != null), result = null, _eos = false;

  WorkerResponse.fromMessage(Map<String, dynamic> message) : result = message[''] , error = message['!'] , stackTrace = message['?'], _eos = message['#'] ?? false;

  final String? error;
  final String? stackTrace;
  final dynamic result;
  final bool _eos;

  bool get endOfStream => _eos;

  Map<String, dynamic> serialize(){
    if (error != null) return {'!': error, '?': stackTrace};
    if (_eos) return {'#': true};
    return {'': result};
  }
}
