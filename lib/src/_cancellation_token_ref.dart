import 'cancellation_token.dart';
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
/// [CancelledException].
class CancellationTokenReference extends CancellationToken {
  CancellationTokenReference._noToken()
      : hasRef = false,
        super(0);

  CancellationTokenReference(int tokenId)
      : hasRef = true,
        super(tokenId);

  static final noToken = CancellationTokenReference._noToken();

  final bool hasRef;

  int refCount = 0;

  @override
  bool get cancelled => _cancelled;
  bool _cancelled = false;

  void cancel() {
    if (hasRef && !_cancelled) {
      _cancelled = true;
      final cancellers = _cancellationCallbacks;
      if (cancellers != null) {
        for (var canceller in cancellers) {
          canceller();
        }
        cancellers.clear();
      }
    }
  }

  List<SquadronCallback>? _cancellationCallbacks;

  void registerStreamCanceller(SquadronCallback canceller) {
    if (_cancelled) {
      canceller();
    } else {
      _cancellationCallbacks ??= <SquadronCallback>[];
      _cancellationCallbacks?.add(canceller);
    }
  }

  void unregisterStreamCanceller(SquadronCallback canceller) {
    _cancellationCallbacks?.remove(canceller);
  }
}
