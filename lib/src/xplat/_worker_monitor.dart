import '../cancellation_token.dart';
import '../worker_pool.dart';
import '../worker_request.dart';
import '../worker_service.dart';
import '../worker_task.dart';

import '_cancellation_token_ref.dart';

/// Each platform worker will instantiate a [WorkerMonitor] responsible for handling cancellation requests. Worker
/// tasks in Squadron may be cancelled in two ways: with a [CancellationToken], giving worker services the chance to
/// handle cancellation requests gracefully, or without a [CancellationToken] via [WorkerPool.cancel] or
/// [Task.cancel].
class WorkerMonitor {
  /// Constructs a new [WorkerMonitor]. The [terminate] callback will be called by [WorkerMonitor.terminate]. This
  /// callback should contain code to shutdown the platform worker and release resources.
  WorkerMonitor(SquadronCallback terminate) : _terminate = terminate;

  final SquadronCallback _terminate;
  bool _terminationRequested = false;
  int _executing = 0;

  final _cancelTokens = <int, CancellationTokenReference>{};

  CancellationTokenReference _getTokenRef(CancellationToken? token) =>
      (token == null)
          ? CancellationTokenReference.noToken
          : _cancelTokens.putIfAbsent(
              token.id, () => CancellationTokenReference(token.id));

  /// Starts monitoring execution of this [request]. If the request contains a cancellation token, it is overridden
  /// with a [CancellationTokenReference] and this reference is rturned to the sender. Otherwise, returns
  /// [CancellationTokenReference.noToken].
  CancellationTokenReference begin(WorkerRequest request) {
    _executing++;
    final tokenRef = _getTokenRef(request.cancelToken);
    tokenRef.usedBy(request);
    return tokenRef;
  }

  Map<int, SquadronCallback>? _streamCancellers;
  int _streamId = 0;

  /// Assigns a stream ID to the stream canceller callback and registers the callback.
  int registerStreamCanceller(
      CancellationTokenReference tokenRef, SquadronCallback canceller) {
    final cancellers = (_streamCancellers ??= <int, SquadronCallback>{});
    final streamId = (++_streamId);
    cancellers[streamId] = canceller;
    tokenRef.addListener(canceller);
    return streamId;
  }

  /// Unregisters the stream cancelled callback associated to the [streamId].
  void unregisterStreamCanceller(
      CancellationTokenReference tokenRef, int streamId) {
    final canceller = _streamCancellers?[streamId];
    if (canceller != null) {
      tokenRef.removeListener(canceller);
      _streamCancellers?.remove(streamId);
    }
  }

  /// Cancels a [token] via the corresponding [CancellationTokenReference].
  void cancelToken(CancellationToken token) => _getTokenRef(token).notifyCancellation();

  /// Cancels a stream via the corresponding [streamId].
  void cancelStream(int streamId) => _streamCancellers?[streamId]?.call();

  /// Stops monitoring execution and releases the [tokenRef].
  void done(CancellationTokenReference tokenRef) {
    tokenRef.release();
    if (tokenRef.refCount == 0 && !tokenRef.cancelled) {
      // track only cancelled tokens
      _cancelTokens.remove(tokenRef.id);
    }
    _executing--;
    if (_terminationRequested && _executing == 0) {
      _terminate();
    }
  }

  /// Terminates the worker monitored by this instance if there is no pending execution. Otherwise, marks
  /// the worker as terminating and termination will be effective when all pending executions are completed.
  void terminate() {
    if (_executing == 0) {
      _terminate();
    } else {
      _terminationRequested = true;
    }
  }
}
