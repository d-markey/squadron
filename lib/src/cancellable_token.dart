import 'cancellation_token.dart';
import 'sequence_id.dart';
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
  CancellableToken([this.message]) : super(SequenceId.instance.next());

  @override
  final String? message;

  bool _cancelled = false;

  @override
  bool get cancelled => _cancelled;

  /// Cancels the token and notifies listeners.
  void cancel() {
    if (!_cancelled) {
      _cancelled = true;
      notifyListeners();
    }
  }

  List<SquadronCallback>? _listeners;

  /// Registers a listener that will be notified when the token is cancelled.
  @override
  void addListener(SquadronCallback listener) {
    _listeners ??= <SquadronCallback>[];
    _listeners!.add(listener);
  }

  @override
  void removeListener(SquadronCallback listener) {
    _listeners?.remove(listener);
  }

  /// Used to notify listeners that have been registered with [addListener], that the token has been cancelled.
  void notifyListeners() => _listeners?.toList().forEach(safeInvoke);
}
