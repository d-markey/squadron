import 'dart:async';

import 'package:cancelation_token/cancelation_token.dart';

import '../_impl/xplat/_token_id.dart';
import '../exceptions/squadron_canceled_exception.dart';

class SquadronCancelationToken extends CancelationToken {
  SquadronCancelationToken._(this.token, this.id) {
    token?.onCanceled.then((_) => _checkToken());
  }

  static const _$id = 0;
  static const _$ex = 1;

  List serialize() {
    _checkToken();
    return List.unmodifiable([
      id,
      exception?.serialize(),
    ]);
  }

  static SquadronCancelationToken? deserialize(List? props) {
    if (props == null) return null;
    final id = props[_$id];
    final ex = SquadronCanceledException.deserialize(props[_$ex]);
    final token = SquadronCancelationToken._(null, id);
    if (ex != null) {
      token._exception = ex;
      token._completer.complete(ex);
    }
    return token;
  }

  static SquadronCancelationToken? wrap(CancelationToken? token) {
    if (token == null) return null;
    final wrapper = SquadronCancelationToken._(token, TokenId.next());
    wrapper._checkToken();
    return wrapper;
  }

  // cancelation token ID
  final String id;

  // reference to the real cancelation token (only set on the caller side, will
  // be `null` in worker threads)
  final CancelationToken? token;

  @override
  SquadronCanceledException? get exception => _exception;
  SquadronCanceledException? _exception;

  @override
  void ensureStarted() {
    token?.ensureStarted();
  }

  @override
  Future<CanceledException> get onCanceled => _completer.future;
  final _completer = Completer<CanceledException>();

  void _checkToken() {
    final ex = token?.exception;
    if (ex != null) {
      _exception ??= SquadronCanceledException.from(id, ex);
      if (!_completer.isCompleted) {
        _completer.complete(ex);
      }
    }
  }
}
