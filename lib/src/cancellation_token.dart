import 'squadron_exception.dart';
import 'worker_service.dart' show SquadronCallback;

/// Cancellation token used in platform workers. These tokens are not designed to be cancelled or listened to by
/// holders. Instead, worker services receiving a [CancellationToken] should verify the token's [cancelled] status
/// and stop processing if the flag is set to [true].
class CancellationToken {
  CancellationToken(this.id);

  static const _$token = 'a';

  /// Deseralization of a [CancellationToken]
  static CancellationToken? deserialize(Map? token) =>
      token == null ? null : CancellationToken(token[_$token]);

  /// The token's id
  final int id;

  /// Flag indicating whether the token was cancelled or not.
  bool get cancelled => false;

  /// Message associated with the token.
  String? get message => null;

  /// Seralization of a [CancellationToken]
  Map serialize() => {_$token: id};

  /// Called just before processing a [WorkerRequest], but should only be implemented by cancellation tokens that
  /// need to cancel automatically after a given period of time, typically a [TimeOutToken].
  void start({SquadronCallback? onTimeout}) {}

  /// Called just after processing a [WorkerRequest]. Should only be used by automatically triggered tokens such as
  /// [TimeOutToken], to ensure the [onTimeout] callback is not called after processing has completed.
  void stop() {}

  /// Registers a listener that will be notified when the token is cancelled. Because a [CancellationToken] is not
  /// designed to be listened to, it always throws a [SquadronException].
  void addListener(SquadronCallback listener) {
    throw SquadronException('A CancellationToken may not be listened to.');
  }

  /// Unregisters a listener that has been installed with [addListener].
  void removeListener(SquadronCallback listener) {}
}
