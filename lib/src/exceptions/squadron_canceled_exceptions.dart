import 'dart:convert';

import 'package:cancelation_token/cancelation_token.dart';
import 'package:meta/meta.dart';

import '_builtin_exceptions.dart';
import 'squadron_canceled_exception.dart';

class SquadronCanceledExceptions extends SquadronCanceledException
    implements CanceledExceptions {
  SquadronCanceledExceptions(
      String tokenId, Iterable<SquadronCanceledException> exceptions)
      : _exceptions = exceptions.toList(),
        super(tokenId, '', null);

  final List<SquadronCanceledException> _exceptions;

  @override
  Iterable<CanceledException> get innerExceptions => _exceptions;

  @override
  String get message => _exceptions.map((e) => e.message).join('\n');

  @override
  StackTrace? get stackTrace => null;

  @override
  String toString() => jsonEncode(serialize());

  @override
  List serialize() => List.unmodifiable([
        $canceledExceptionsType,
        tokenId,
        _exceptions.map((e) => e.serialize()).toList(),
      ]);
}

const _$type = 0;
const _$tokenId = 1;
const _$innerExceptions = 2;

@internal
extension SquadronCanceledExceptionsExt on SquadronCanceledExceptions {
  static SquadronCanceledExceptions? deserialize(List? props) {
    if (props == null) return null;
    if (props[_$type] != $canceledExceptionsType) return null;
    return SquadronCanceledExceptions(
      props[_$tokenId],
      props[_$innerExceptions].map(SquadronCanceledExceptionExt.deserialize),
    );
  }
}
