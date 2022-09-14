import 'worker_exception.dart';
import 'worker_request.dart';
import 'worker_service.dart' show SquadronCallback;
import 'xplat/_helpers.dart';
import 'xplat/_sequence_id.dart';

/// Base cancellation token.
class CancellationToken {
  CancellationToken._(this.message, this._id);

  CancellationToken([String? message]) : this._(message, SequenceId.next());

  static const _$id = 0;
  static const _$message = 1;

  /// Deseralization of a [CancellationToken]
  static CancellationToken? deserialize(List? token) {
    if (token == null) return null;
    return CancellationToken._(token[_$message], token[_$id]);
  }

  /// The token's id
  int get id => _id;
  int _id;

  /// Flag indicating whether the token was cancelled or not.
  bool get cancelled => exception != null;

  /// Exception to be thrown upon cancellation
  CancelledException? get exception => _exception;
  CancelledException? _exception;

  /// Message associated with the token.
  final String? message;

  /// Seralization of a [CancellationToken]
  List serialize() => [_id, message];

  /// Cancels the token and notifies listeners.
  void cancel([CancelledException? exception]) {
    _exception ??= (exception ?? CancelledException(message: message));
    for (var listener in _listeners ?? const []) {
      safeInvoke(listener);
    }
  }

  List<SquadronCallback>? _listeners;

  /// Registers a [listener] that will be notified when the token is cancelled. If the token is already cancelled,
  /// the [listener] will be called immediately.
  void addListener(SquadronCallback listener) {
    if (cancelled) {
      safeInvoke(listener);
    } else {
      (_listeners ??= <SquadronCallback>[]).add(listener);
    }
  }

  /// Unregisters a listener that has been installed with [addListener].
  void removeListener(SquadronCallback listener) =>
      _listeners?.remove(listener);

  /// Called just before processing a [WorkerRequest], but should only be implemented by cancellation tokens that
  /// need to cancel automatically.
  void ensureStarted() {}

  /// Await this method in Worker code to give cancellation requests a chance
  /// to come through.
  Future<bool> isCancelled({bool throwIfCancelled = false}) =>
      Future.delayed(Duration.zero, () {
        // throw if the token has been cancelled
        final ex = exception;
        if (ex == null) return false;
        return throwIfCancelled ? throw ex : true;
      });
}

// for internal use
extension TokenIdExt on CancellationToken {
  void withId(int id) => _id = id;
}
