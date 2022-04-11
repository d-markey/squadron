import 'squadron_error.dart';
import 'worker_exception.dart';
import 'worker_request.dart';
import 'worker_service.dart' show SquadronCallback;

/// Cancellation token used in platform workers. These tokens are not designed to be cancelled or listened to by
/// holders. Instead, worker services receiving a [CancellationToken] should verify the token's [cancelled] status
/// and stop processing if the flag is set to [true].
class CancellationToken {
  CancellationToken(this.id, [String? message]) : _message = message;

  static const _$token = 'a';
  static const _$message = 'b';

  /// Deseralization of a [CancellationToken]
  static CancellationToken? deserialize(Map? token) => (token == null)
      ? null
      : CancellationToken(token[_$token], token[_$message]);

  /// The token's id
  final int id;

  /// Flag indicating whether the token was cancelled or not.
  bool get cancelled => exception != null;

  /// Exception to be thrown upon cancellation
  CancelledException? get exception => null;

  /// Message associated with the token.
  String? get message => _message;
  final String? _message;

  /// Seralization of a [CancellationToken]
  Map serialize() => {_$token: id, _$message: _message};

  /// Called just before processing a [WorkerRequest], but should only be implemented by cancellation tokens that
  /// need to cancel automatically.
  void ensureStarted() {}

  /// Registers a listener that will be notified when the token is cancelled. Because a [CancellationToken] is not
  /// designed to be listened to, it always throws a [SquadronError].
  void addListener(SquadronCallback listener) =>
      throw newSquadronError('CancellationToken may not be listened to');

  /// Unregisters a listener that has been installed with [addListener].
  void removeListener(SquadronCallback listener) {}
}
