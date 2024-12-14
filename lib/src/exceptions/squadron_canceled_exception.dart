import 'package:cancelation_token/cancelation_token.dart';
import 'package:meta/meta.dart';

import '_builtin_exceptions.dart';
import 'squadron_canceled_exceptions.dart';
import 'squadron_exception.dart';
import 'squadron_timeout_exception.dart';

class SquadronCanceledException extends SquadronException
    implements CanceledException {
  SquadronCanceledException(
      this.tokenId, String message, StackTrace? stackTrace)
      : super.init(message, stackTrace);

  factory SquadronCanceledException.from(String tokenId, CanceledException ex,
      [StackTrace? stackTrace]) {
    if (ex is TimeoutCanceledException) {
      return SquadronTimeoutException(
          tokenId, ex.message, ex.duration, ex.stackTrace);
    } else if (ex is CanceledExceptions) {
      return SquadronCanceledExceptions(
        tokenId,
        ex.innerExceptions.map(
          (e) => SquadronCanceledException.from(tokenId, e, e.stackTrace),
        ),
      );
    } else {
      return SquadronCanceledException(tokenId, ex.message, ex.stackTrace);
    }
  }

  final String tokenId;

  @override
  List serialize() => List.unmodifiable([
        $canceledExceptionType,
        tokenId,
        message,
        stackTrace?.toString(),
      ]);
}

const _$type = 0;
const _$tokenId = 1;
const _$message = 2;
const _$stackTrace = 3;

@internal
extension SquadronCanceledExceptionExt on SquadronCanceledException {
  static SquadronCanceledException? deserialize(List? props) {
    if (props == null) return null;
    switch (props[_$type]) {
      case $canceledExceptionType:
        return SquadronCanceledException(
          props[_$tokenId],
          props[_$message],
          SquadronException.loadStackTrace(props[_$stackTrace]),
        );
      case $canceledExceptionsType:
        return SquadronCanceledExceptionsExt.deserialize(props);
      case $timeoutExceptionType:
        return SquadronTimeoutExceptionExt.deserialize(props);
      default:
        return null;
    }
  }
}
