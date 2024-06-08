import 'dart:async';

import 'package:cancelation_token/cancelation_token.dart';

import '../exceptions/squadron_canceled_exception.dart';
import '../exceptions/squadron_error.dart';
import '../worker/worker_request.dart';
import '_squadron_cancelation_token.dart';

/// Cancelation token reference. This special cancelation token is managed by the [WorkerMonitor] and is used to
/// mirror cancelation tokens presented to Squadron by callers of a worker service. When a [WorkerRequest] is
/// handled by the platform worker and that request is associated with a cancelation request, the [WorkerMonitor]
/// will override the request's cancelation token with a [CancelationTokenReference]. The same cancelation may
/// be used for several service calls, so the [WorkerMonitor] keeps a map of [CancelationTokenReference] and a
/// reference count that is incremented for each [WorkerRequest] having the same cancelation token and decremented
/// when processing is finished. When the reference count drops to 0 and the cancelation token was not canceled,
/// the [CancelationTokenReference] is removed from the map.
///
/// When a caller cancels a token, a cancelation notification is sent to all workers in the pool and the
/// corresponding [CancelationTokenReference] will be canceled. Services executing in the context of a platform
/// worker will be able to inspect the token's status to interrupt processing gracefully. If the token's status is
/// not inspected, processing will continue in platform workers, but will be interrupted on caller-side with a
/// [CanceledException].
class CancelationTokenReference implements SquadronCancelationToken {
  CancelationTokenReference._noToken()
      : _hasRef = false,
        id = '' {
    _refCount = 1;
  }

  @override
  final String id;

  /// Singleton token reference instance for requests containing no token.
  static final noToken = CancelationTokenReference._noToken();

  /// Creates a new token reference for [id].
  CancelationTokenReference(this.id) : _hasRef = true;

  @override
  SquadronCanceledException? get exception => _exception;
  SquadronCanceledException? _exception;

  @override
  bool get isCanceled => (_exception != null);

  @override
  Future<CanceledException> get onCanceled => _completer.future;
  final _completer = Completer<SquadronCanceledException>();

  /// Whether this token reference instance has a reference. A token reference
  /// without a reference does nothing.
  final bool _hasRef;

  /// Reference counter.
  int get refCount => _refCount;
  int _refCount = 0;

  /// Use this token reference for [request]. Increments the internal reference
  /// counter and overrides [WorkerRequest.cancelToken] with this token.
  void usedBy(WorkerRequest request) {
    if (_hasRef) {
      _refCount++;
      request.overrideCancelToken(this);
    } else if (request.cancelToken != null) {
      throw SquadronErrorExt.create('Token reference mismatch');
    }
  }

  /// Release this token reference. Decrements the internal reference counter.
  void release() {
    if (_hasRef) {
      _refCount--;
    }
  }

  void update(SquadronCancelationToken token) {
    final ex = token.exception;
    if (ex != null && !_completer.isCompleted) {
      _exception = ex;
      _completer.complete(ex);
    }
  }

  @override
  void ensureStarted() {/* nothing to do */}

  @override
  void throwIfCanceled() {
    if (_exception != null) {
      throw _exception!;
    }
  }

  @override
  Future<void> refreshAndThrowIfCanceled() => Future(throwIfCanceled);

  @override
  // no native cancelation token in workers
  CancelationToken? get token => throw UnimplementedError();

  @override
  // serialization of token references
  List serialize() => throw UnimplementedError();
}
