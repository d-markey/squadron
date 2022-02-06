import 'cancellation_token.dart';
import '_sequence_id.dart';
import 'worker_exception.dart';
import 'worker_service.dart' show SquadronCallback;

void safeInvoke(SquadronCallback? callback) {
  try {
    if (callback != null) {
      callback();
    }
  } catch (e) {
    print('notification to listener $callback failed: $e');
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

  void setException(CancelledException exception) {
    _exception ??= exception;
    _listeners?.toList().forEach(safeInvoke);
  }

  /// Cancels the token and notifies listeners.
  void cancel() =>
      setException(_exception ?? CancelledException(message: message));

  List<SquadronCallback>? _listeners;

  /// Registers a listener that will be notified when the token is cancelled.
  @override
  void addListener(SquadronCallback listener) =>
      _listeners = (_listeners ?? <SquadronCallback>[])..add(listener);

  @override
  void removeListener(SquadronCallback listener) =>
      _listeners?.remove(listener);
}
