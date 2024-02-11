import 'package:cancelation_token/cancelation_token.dart';

import '_well_known_exceptions.dart';
import 'squadron_canceled_exception.dart';

class SquadronCanceledExceptions
    implements SquadronCanceledException, CanceledExceptions {
  SquadronCanceledExceptions(
      this.tokenId, Iterable<SquadronCanceledException> exceptions)
      : _exceptions = exceptions.toList();

  @override
  final String tokenId;

  final List<SquadronCanceledException> _exceptions;

  @override
  Iterable<CanceledException> get innerExceptions => _exceptions;

  @override
  String get message => _exceptions.map((e) => e.message).join('\n');

  @override
  StackTrace? get stackTrace => null;

  static const _$type = 0;
  static const _$tokenId = 1;
  static const _$innerExceptions = 2;

  @override
  List serialize() => List.unmodifiable([
        $canceledExceptionsType,
        tokenId,
        _exceptions.map((e) => e.serialize()),
      ]);

  static SquadronCanceledExceptions? deserialize(List? props) {
    if (props == null) return null;
    if (props[_$type] != $canceledExceptionsType) return null;
    return SquadronCanceledExceptions(
      props[_$tokenId],
      props[_$innerExceptions].map(SquadronCanceledException.deserialize),
    );
  }
}
