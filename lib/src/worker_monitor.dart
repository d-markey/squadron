import 'cancellation_token.dart';
import 'worker_request.dart';

class CancellationTokenReference extends CancellationToken {
  CancellationTokenReference(CancellationToken token)
      : super(token.token);

  int refCount = 0;

  @override
  bool get cancelled => _cancelled;
  bool _cancelled = false;

  @override
  String? get message => _message;
  String? _message;

  void cancel(String? message) {
    _message ??= message;
    _cancelled |= true;
  }
}

class WorkerMonitor {
  WorkerMonitor(this._terminate);

  final void Function() _terminate;
  bool _terminationRequested = false;
  int _executing = 0;

  final cancelTokens = <int, CancellationTokenReference>{};

  CancellationTokenReference? _getTokenRef(CancellationToken? token) =>
      (token == null)
          ? null
          : cancelTokens.putIfAbsent(
              token.token, () => CancellationTokenReference(token));

  CancellationTokenReference? begin(WorkerRequest request) {
    _executing++;
    final tokenRef = _getTokenRef(request.cancelToken);
    if (tokenRef != null) {
      tokenRef.refCount++;
      request.overrideCancelToken(tokenRef);
    }
    return tokenRef;
  }

  void cancel(CancellationToken token, String? message) => _getTokenRef(token)?.cancel(message ?? 'The task has been cancelled');

  void done(CancellationTokenReference? tokenRef) {
    if (tokenRef != null) {
      tokenRef.refCount--;
      if (tokenRef.refCount == 0 && !tokenRef.cancelled) {
        // track only cancelled tokens
        cancelTokens.remove(tokenRef.token);
      }
    }
    _executing--;
    if (_terminationRequested && _executing == 0) {
      _terminate();
    }
  }

  void terminate() {
    if (_executing == 0) {
      _terminate();
    } else {
      _terminationRequested = true;
    }
  }
}
