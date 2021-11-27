import 'cancellation_token.dart';
import 'worker_request.dart';
import 'worker_service.dart';

/// Cancellation token reference. This special cancellation token is managed by the [WorkerMonitor] and is used to
/// mirror' cancellation tokens presented to Squadron by callers of a worker service. When a [WorkerRequest] is
/// handled by the platform worker and that request is associated with a cancellation request, the [WorkerMonitor]
/// will override the request's cancellation token with a [_CancellationTokenReference]. The same cancellation may
/// be used for several service calls, so the [WorkerMonitor] keeps a map of [_CancellationTokenReference] and a
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
  _CancellationTokenReference(CancellationToken token) : super(token.id);

  int refCount = 0;

  @override
  bool get cancelled => _cancelled;
  bool _cancelled = false;

  @override
  String? get message => _message;
  String? _message;

  void _cancel(String? message) {
    _message ??= message;
    _cancelled |= true;
  }
}

/// Each platform worker will instantiate a [WorkerMonitor] responsible for handling cancellation requests. Worker
/// tasks in Squadron may be cancelled in two ways: with a [CancellationToken], giving worker services the chance to
/// handle cancellation requests gracefully, or without a [CancellationToken] via [WorkerPool.cancel()] or
/// [WorkerTask.cancel()].
class WorkerMonitor {
  WorkerMonitor(this._terminate);

  final SquadronCallback _terminate;
  bool _terminationRequested = false;
  int _executing = 0;

  final cancelTokens = <int, _CancellationTokenReference>{};

  _CancellationTokenReference? _getTokenRef(CancellationToken? token) =>
      (token == null)
          ? null
          : cancelTokens.putIfAbsent(
              token.id, () => _CancellationTokenReference(token));

  _CancellationTokenReference? begin(WorkerRequest request) {
    _executing++;
    final tokenRef = _getTokenRef(request.cancelToken);
    if (tokenRef != null) {
      tokenRef.refCount++;
      request.overrideCancelToken(tokenRef);
    }
    return tokenRef;
  }

  void cancel(CancellationToken token, String? message) =>
      _getTokenRef(token)?._cancel(message ?? 'The task has been cancelled');

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
