import 'dart:async';

import '../../tokens/cancellation_token.dart';
import '../../worker/worker_pool.dart';
import '../../worker/worker_request.dart';
import '../../worker/worker_service.dart';
import '../../worker/worker_task.dart';
import '_cancellation_token_ref.dart';

/// Each platform worker will instantiate a [WorkerMonitor] responsible for
/// handling cancellation requests. Worker tasks in Squadron may be cancelled in
/// two ways: with a [CancellationToken], giving worker services the chance to
/// handle cancellation requests gracefully, or without a [CancellationToken]
/// via [WorkerPool.cancel] or [Task.cancel].
class WorkerMonitor {
  /// Constructs a new [WorkerMonitor]. The [_terminate] callback will be called
  /// by [WorkerMonitor.terminate]. This callback should contain code to
  /// shutdown the platform worker and release resources.
  WorkerMonitor(this._terminate);

  final SquadronCallback _terminate;
  bool _terminationRequested = false;
  int _executing = 0;
  ServiceInstaller? _installer;

  final _cancelTokens = <String, CancellationTokenReference>{};

  CancellationTokenReference _getTokenRef(CancellationToken? token) =>
      (token == null)
          ? CancellationTokenReference.noToken
          : _cancelTokens.putIfAbsent(
              token.id, () => CancellationTokenReference(token.id));

  /// Starts monitoring execution of this [request]. If the request contains a cancellation token, it
  /// is overridden with a [CancellationTokenReference] and this reference is returned to the sender.
  /// Otherwise, returns [CancellationTokenReference.noToken].
  CancellationTokenReference begin(WorkerRequest request) {
    _executing++;
    final token = _getTokenRef(request.cancelToken);
    token.usedBy(request);
    return token;
  }

  Map<int, SquadronCallback>? _streamCancellers;
  int _streamId = 0;

  /// Assigns a stream ID to the stream canceller callback and registers the callback.
  int registerStreamCanceller(
      CancellationTokenReference tokenRef, SquadronCallback canceller) {
    final streamId = ++_streamId;
    (_streamCancellers ??= <int, SquadronCallback>{})[streamId] = canceller;
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
  void cancelToken(CancellationToken token) =>
      _getTokenRef(token).notifyCancellation();

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
      _shutdown();
    }
  }

  /// Installs the service if it implements [ServiceInstaller].
  FutureOr<void> install(WorkerService service) {
    if (service is ServiceInstaller) {
      final installer = service as ServiceInstaller;
      _installer = installer;
      return installer.install();
    }
  }

  /// Installs the service if it implements [ServiceInstaller].
  FutureOr<void> _uninstall(ServiceInstaller? installer) {
    if (installer != null) {
      try {
        var res = installer.uninstall();
        if (res is Future<void>) {
          res = res.onError((error, stackTrace) => {/* swallow excepions */});
        }
        return res;
      } catch (ex) {/* swallow exceptions*/}
    }
  }

  /// Terminates the worker monitored by this instance if there is no pending execution. Otherwise, marks
  /// the worker as terminating and termination will be effective when all pending executions are completed.
  void terminate() {
    if (_executing == 0) {
      _shutdown();
    } else {
      _terminationRequested = true;
    }
  }

  void _shutdown() {
    final uninstall = _uninstall(_installer);
    if (uninstall is Future) {
      uninstall.whenComplete(_terminate);
    } else {
      _terminate();
    }
  }
}
