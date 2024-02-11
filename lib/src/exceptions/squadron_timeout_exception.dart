import 'package:cancelation_token/cancelation_token.dart';

import '_well_known_exceptions.dart';
import 'squadron_canceled_exception.dart';
import 'squadron_exception.dart';

class SquadronTimeoutException extends SquadronCanceledException
    implements TimeoutCanceledException {
  SquadronTimeoutException(
      String tokenId, String message, this.duration, StackTrace? stackTrace)
      : super(tokenId, message, stackTrace);

  @override
  final Duration? duration;

  static const _$type = 0;
  static const _$tokenId = 1;
  static const _$message = 2;
  static const _$stackTrace = 3;
  static const _$duration = 4;

  @override
  List serialize() => List.unmodifiable([
        $timeoutExceptionType,
        tokenId,
        message,
        stackTrace?.toString(),
        duration?.inMicroseconds,
      ]);

  static SquadronTimeoutException? deserialize(List? props) {
    if (props == null) return null;
    if (props[_$type] != $timeoutExceptionType) return null;
    final microSecs = props[_$duration];
    return SquadronTimeoutException(
      props[_$tokenId],
      props[_$message],
      (microSecs == null) ? null : Duration(microseconds: microSecs),
      SquadronException.loadStackTrace(props[_$stackTrace]),
    );
  }
}
