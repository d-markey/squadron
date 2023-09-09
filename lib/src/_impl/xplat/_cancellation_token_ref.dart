import '../../exceptions/squadron_error.dart';
import '../../exceptions/worker_exception.dart';
import '../../tokens/cancellation_token.dart';
import '../../worker/worker_request.dart';
import '../../worker/worker_service.dart';
import '_worker_monitor.dart';

/// Cancellation token reference. This special cancellation token is managed by the [WorkerMonitor] and is used to
/// mirror' cancellation tokens presented to Squadron by callers of a worker service. When a [WorkerRequest] is
/// handled by the platform worker and that request is associated with a cancellation request, the [WorkerMonitor]
/// will override the request's cancellation token with a [CancellationTokenReference]. The same cancellation may
/// be used for several service calls, so the [WorkerMonitor] keeps a map of [CancellationTokenReference] and a
/// reference count that is incremented for each [WorkerRequest] having the same cancellation token and decremented
/// when processing is finished. When the reference count drops to 0 and the cancellation token was not cancelled,
/// the [CancellationTokenReference] is removed from the map.
///
/// When a caller cancels a token, a cancellation notification is sent to all workers in the pool and the
/// corresponding [CancellationTokenReference] will be cancelled. Services executing in the context of a platform
/// worker will be able to inspect the token's status to interrupt processing gracefully. If the token's status is
/// not inspected, processing will continue in platform workers, but will be interrupted on caller-side with a
/// [CancelledException].
class CancellationTokenReference extends CancellationToken {
  CancellationTokenReference._noToken() : _hasRef = false {
    _refCount = 1;
    withId('');
  }

  /// Singleton token reference instance for requests containing no token.
  static final noToken = CancellationTokenReference._noToken();

  /// Creates a new token reference for [tokenId].
  CancellationTokenReference(String tokenId) : _hasRef = true {
    withId(tokenId);
  }

  /// Whether this token reference instance has a reference. A token ref without a reference does nothing.
  final bool _hasRef;

  /// Reference counter.
  int get refCount => _refCount;
  int _refCount = 0;

  /// Use this token reference for [request]. Increments the internal reference counter and overrides the
  /// [WorkerRequest.cancelToken] with this reference.
  void usedBy(WorkerRequest request) {
    if (_hasRef) {
      _refCount++;
      request.overrideCancelToken(this);
    } else if (request.cancelToken != null) {
      throw SquadronErrorExt.create(
          'Token reference mismatch', StackTrace.current);
    }
  }

  /// Release this token reference. Decrements the internal reference counter.
  void release() {
    if (_hasRef) {
      _refCount--;
    }
  }

  @override
  void cancel([CancelledException? exception]) {
    throw WorkerException('CancellationToken cannot be cancelled by worker');
  }

  void notifyCancellation() {
    if (_hasRef) {
      super.cancel();
    }
  }

  @override
  void addListener(SquadronCallback listener) {
    if (_hasRef) {
      super.addListener(listener);
    }
  }

  @override
  void removeListener(SquadronCallback listener) {
    if (_hasRef) {
      super.removeListener(listener);
    }
  }
}
