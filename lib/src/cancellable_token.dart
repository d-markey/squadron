import 'cancellation_token.dart';
import '_sequence_id.dart';
import 'squadron.dart';
import 'worker_exception.dart';
import 'worker_service.dart' show SquadronCallback;

void _safeInvoke(SquadronCallback? callback) {
  try {
    if (callback != null) {
      callback();
    }
  } catch (e) {
    Squadron.warning('notification to listener $callback failed: $e');
  }
}

/// Base class for cancellation tokens used by callers of worker services. It implements the logic to register,
/// notify and unregister token listeners. This cancellation token can be cancelled programmatically by calling
/// [cancel].
class CancellableToken extends CancellationToken {
  CancellableToken([String? message])
      : super(SequenceId.instance.next(), message);

  @override
  CancelledException? get exception => _exception;
  CancelledException? _exception;

  /// Cancels the token and notifies listeners.
  void cancel([CancelledException? exception]) {
    _exception ??= exception ?? CancelledException(message: message);
    _listeners?.toList().forEach(_safeInvoke);
  }

  List<SquadronCallback>? _listeners;

  /// Registers a listener that will be notified when the token is cancelled.
  @override
  void addListener(SquadronCallback listener) =>
      _listeners = (_listeners ?? <SquadronCallback>[])..add(listener);

  @override
  void removeListener(SquadronCallback listener) =>
      _listeners?.remove(listener);
}
