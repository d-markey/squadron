import 'package:meta/meta.dart';

import '../exceptions/worker_exception.dart';
import '../_impl/xplat/_helpers.dart';
import '../_impl/xplat/_token_id.dart';
import '../worker/worker_request.dart';
import '../worker/worker_service.dart' show SquadronCallback;

/// Base cancellation token.
class CancellationToken {
  CancellationToken._(this.message, this._id);

  CancellationToken([String? message]) : this._(message, TokenId.next());

  static const _$id = 0;
  static const _$message = 1;

  /// Message associated with the token.
  final String? message;

  /// The token's id
  String get id => _id;
  String _id;

  /// Exception to be thrown upon cancellation
  CancelledException? get exception => _exception;
  CancelledException? _exception;

  /// Flag indicating whether the token was cancelled or not.
  bool get cancelled => exception != null;

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

  /// Cancels the token and notifies listeners.
  void cancel([CancelledException? exception]) {
    _exception ??= (exception ?? CancelledException(message: message));
    for (var listener in _listeners ?? const []) {
      safeInvoke(listener);
    }
  }

  /// Called just before processing a [WorkerRequest], but should only be implemented by cancellation
  /// tokens that need to cancel automatically (eg. a timeout token).
  void ensureStarted() {}

  /// Synchronously check whether the token has been cancelled.
  bool isCancelledSync({bool throwIfCancelled = false}) {
    final ex = exception;
    return (ex == null)
        ? false
        : throwIfCancelled
            ? throw ex
            : true;
  }

  /// Await this method in Worker code to give cancellation requests a chance
  /// to come through.
  Future<bool> isCancelled({bool throwIfCancelled = false}) =>
      Future(() => isCancelledSync(throwIfCancelled: throwIfCancelled));

  /// Unregisters a listener that has been installed with [addListener].
  void removeListener(SquadronCallback listener) =>
      _listeners?.remove(listener);

  /// Seralization of a [CancellationToken]
  List serialize() => List.unmodifiable([_id, message]);

  /// Deseralization of a [CancellationToken]
  static CancellationToken? deserialize(List? token) {
    if (token == null) return null;
    return CancellationToken._(token[_$message], token[_$id]);
  }
}

@internal
extension TokenIdExt on CancellationToken {
  void withId(String id) => _id = id;
}