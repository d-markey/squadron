part of '_bootstrapper_stub.dart';

/// Cancellation token reference. This special cancellation token is managed by the [_WorkerMonitor] and is used to
/// mirror' cancellation tokens presented to Squadron by callers of a worker service. When a [WorkerRequest] is
/// handled by the platform worker and that request is associated with a cancellation request, the [_WorkerMonitor]
/// will override the request's cancellation token with a [_CancellationTokenReference]. The same cancellation may
/// be used for several service calls, so the [_WorkerMonitor] keeps a map of [_CancellationTokenReference] and a
/// reference count that is incremented for each [WorkerRequest] having the same cancellation token and decremented
/// when processing is finished. When the reference count drops to 0 and the cancellation token was not cancelled,
/// the [_CancellationTokenReference] is removed from the map.
///
/// When a caller cancels a token, a cancellation notification is sent to all workers in the pool and the
/// corresponding [_CancellationTokenReference] will be cancelled. Services executing in the context of a platform
/// worker will be able to inspect the token's status to interrupt processing gracefully. If the token's status is
/// not inspected, processing will continue in platform workers, but will be interrupted on caller-side with a
/// [CancellationException].
class _CancellationTokenReference extends CancellationToken {
  _CancellationTokenReference(CancellationToken token)
      : super(token.id, token.message);

  int refCount = 0;

  @override
  CancelledException? get exception => _exception;
  CancelledException? _exception;

  void _cancel() {
    _exception ??= CancelledException();
  }
}

/// Each platform worker will instantiate a [_WorkerMonitor] responsible for handling cancellation requests. Worker
/// tasks in Squadron may be cancelled in two ways: with a [CancellationToken], giving worker services the chance to
/// handle cancellation requests gracefully, or without a [CancellationToken] via [WorkerPool.cancel()] or
/// [WorkerTask.cancel()].
class _WorkerMonitor {
  _WorkerMonitor(this._terminate);

  final SquadronCallback _terminate;
  bool _terminationRequested = false;
  int _executing = 0;

  final cancelTokens = <int, _CancellationTokenReference>{};

  _CancellationTokenReference _getTokenRef(CancellationToken token) =>
      cancelTokens.putIfAbsent(
          token.id, () => _CancellationTokenReference(token));

  _CancellationTokenReference? begin(WorkerRequest request) {
    _executing++;
    var token = request.cancelToken;
    if (token == null) return null;
    final tokenRef = _getTokenRef(token);
    tokenRef.refCount++;
    request.overrideCancelToken(tokenRef);
    return tokenRef;
  }

  void cancel(CancellationToken token) => _getTokenRef(token)._cancel();

  void done(_CancellationTokenReference? tokenRef) {
    if (tokenRef != null) {
      tokenRef.refCount--;
      if (tokenRef.refCount == 0 && !tokenRef.cancelled) {
        // track only cancelled tokens
        cancelTokens.remove(tokenRef.id);
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
