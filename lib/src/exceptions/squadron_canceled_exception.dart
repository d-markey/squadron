import 'package:cancelation_token/cancelation_token.dart';

import '_well_known_exceptions.dart';
import 'squadron_canceled_exceptions.dart';
import 'squadron_exception.dart';
import 'squadron_timeout_exception.dart';

class SquadronCanceledException
    implements CanceledException, SquadronException {
  SquadronCanceledException(this.tokenId, this.message, this.stackTrace);

  factory SquadronCanceledException.from(String tokenId, CanceledException ex) {
    if (ex is TimeoutCanceledException) {
      return SquadronTimeoutException(
          tokenId, ex.message, ex.duration, ex.stackTrace);
    } else if (ex is CanceledExceptions) {
      return SquadronCanceledExceptions(
        tokenId,
        ex.innerExceptions
            .map((e) => SquadronCanceledException.from(tokenId, e)),
      );
    } else {
      return SquadronCanceledException(tokenId, ex.message, ex.stackTrace);
    }
  }

  final String tokenId;

  @override
  final String message;

  @override
  final StackTrace? stackTrace;

  static const _$type = 0;
  static const _$tokenId = 1;
  static const _$message = 2;
  static const _$stackTrace = 3;

  @override
  List serialize() => List.unmodifiable([
        $canceledExceptionType,
        tokenId,
        message,
        stackTrace?.toString(),
      ]);

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
        return SquadronCanceledExceptions.deserialize(props);
      case $timeoutExceptionType:
        return SquadronTimeoutException.deserialize(props);
      default:
        return null;
    }
  }
}
