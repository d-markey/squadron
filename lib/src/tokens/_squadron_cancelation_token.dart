import 'dart:async';

import 'package:cancelation_token/cancelation_token.dart';
import 'package:meta/meta.dart';

import '../_impl/xplat/_token_id.dart';
import '../exceptions/squadron_canceled_exception.dart';

class SquadronCancelationToken extends CancelationToken {
  SquadronCancelationToken._(this.token, this.id) {
    token?.onCanceled.then(_checkToken);
  }

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

  void _checkToken([dynamic _]) {
    final ex = token?.exception;
    if (ex != null) {
      _exception ??= SquadronCanceledException.from(id, ex);
      if (!_completer.isCompleted) {
        _completer.complete(_exception);
      }
    }
  }
}

const _$id = 0;
const _$ex = 1;

@internal
extension SquadronCancelationTokenExt on CancelationToken? {
  SquadronCancelationToken? wrap() {
    final self = this;
    if (self == null) return null;
    if (self is SquadronCancelationToken) return self;
    return SquadronCancelationToken._(self, '${TokenId.next()}@$hashCode')
      .._checkToken();
  }
}
