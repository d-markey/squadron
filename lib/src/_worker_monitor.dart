import '_cancellation_token_ref.dart';
import 'cancellation_token.dart';
import 'worker_pool.dart';
import 'worker_request.dart';
import 'worker_service.dart';
import 'worker_task.dart';

/// Each platform worker will instantiate a [WorkerMonitor] responsible for handling cancellation requests. Worker
/// tasks in Squadron may be cancelled in two ways: with a [CancellationToken], giving worker services the chance to
/// handle cancellation requests gracefully, or without a [CancellationToken] via [WorkerPool.cancel] or
/// [WorkerTask.cancel].
class WorkerMonitor {
  WorkerMonitor(this._terminate);

  final SquadronCallback _terminate;
  bool _terminationRequested = false;
  int _executing = 0;

  final _cancelTokens = <int, CancellationTokenReference>{};

  CancellationTokenReference _getTokenRef(CancellationToken? token) =>
      (token == null)
          ? CancellationTokenReference.noToken
          : _cancelTokens.putIfAbsent(
              token.id, () => CancellationTokenReference(token.id));

  CancellationTokenReference begin(WorkerRequest request) {
    _executing++;
    final tokenRef = _getTokenRef(request.cancelToken);
    if (tokenRef.hasRef) {
      tokenRef.refCount++;
      request.overrideCancelToken(tokenRef);
    }
    return tokenRef;
  }

  Map<int, SquadronCallback>? _streamCancellers;
  int _streamId = 0;

  int registerStreamCanceller(SquadronCallback canceller) {
    final cancellers = (_streamCancellers ??= <int, SquadronCallback>{});
    final streamId = (++_streamId);
    cancellers[streamId] = canceller;
    return streamId;
  }

  void unregisterStreamCanceller(int streamId) {
    _streamCancellers?.remove(streamId);
  }

  void cancel(CancellationToken token) => _getTokenRef(token).cancel();

  void cancelStream(int streamId) => _streamCancellers?[streamId]?.call();

  void done(CancellationTokenReference tokenRef) {
    if (tokenRef.hasRef) {
      tokenRef.refCount--;
      if (tokenRef.refCount == 0 && !tokenRef.cancelled) {
        // track only cancelled tokens
        _cancelTokens.remove(tokenRef.id);
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
