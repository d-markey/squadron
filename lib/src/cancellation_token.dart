import 'worker_exception.dart';
import 'worker_request.dart';
import 'worker_service.dart' show SquadronCallback;
import 'xplat/_helpers.dart';
import 'xplat/_sequence_id.dart';

/// Base cancellation token.
class CancellationToken {
  CancellationToken([String? message])
      : _message = message, _id = SequenceId.next();

  static const _$token = 'a';
  static const _$message = 'b';

  /// Deseralization of a [CancellationToken]
  static CancellationToken? deserialize(Map? token) {
    if (token == null) return null;
    final tok = CancellationToken(token[_$message]);
    tok._id = token[_$token];
    return tok;
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
  String? get message => _message;
  final String? _message;

  /// Seralization of a [CancellationToken]
  Map serialize() => {_$token: id, _$message: _message};

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
      _listeners ??= <SquadronCallback>[];
      _listeners!.add(listener);
    }
  }

  /// Unregisters a listener that has been installed with [addListener].
  void removeListener(SquadronCallback listener) =>
      _listeners?.remove(listener);

  /// Called just before processing a [WorkerRequest], but should only be implemented by cancellation tokens that
  /// need to cancel automatically.
  void ensureStarted() {}
}

// for internal use
extension TokenIdExt on CancellationToken {
  void withId(int id) => _id = id;
}
