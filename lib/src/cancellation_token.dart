import 'package:meta/meta.dart';

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

  /// Message associated with the token.
  final String? message;

  /// The token's id
  int get id => _id;
  int _id;

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

  /// Await this method in Worker code to give cancellation requests a chance
  /// to come through.
  Future<bool> isCancelled({bool throwIfCancelled = false}) => Future(() {
        // throw if the token has been cancelled
        final ex = exception;
        return (ex == null)
            ? false
            : throwIfCancelled
                ? throw ex
                : true;
      });

  /// Unregisters a listener that has been installed with [addListener].
  void removeListener(SquadronCallback listener) =>
      _listeners?.remove(listener);

  /// Seralization of a [CancellationToken]
  List serialize() => [_id, message];

  /// Deseralization of a [CancellationToken]
  static CancellationToken? deserialize(List? token) {
    if (token == null) return null;
    return CancellationToken._(token[_$message], token[_$id]);
  }
}

@internal
extension TokenIdExt on CancellationToken {
  void withId(int id) => _id = id;
}
