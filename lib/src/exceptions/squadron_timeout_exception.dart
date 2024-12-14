import 'package:cancelation_token/cancelation_token.dart';
import 'package:meta/meta.dart';

import '_builtin_exceptions.dart';
import 'squadron_canceled_exception.dart';
import 'squadron_exception.dart';

class SquadronTimeoutException extends SquadronCanceledException
    implements TimeoutCanceledException {
  SquadronTimeoutException(String tokenId, String message, this.duration,
      [StackTrace? stackTrace])
      : super(tokenId, message, stackTrace);

  @override
  final Duration? duration;

  @override
  List serialize() => List.unmodifiable([
        $timeoutExceptionType,
        tokenId,
        message,
        stackTrace?.toString(),
        duration?.inMicroseconds,
      ]);
}

const _$type = 0;
const _$tokenId = 1;
const _$message = 2;
const _$stackTrace = 3;
const _$duration = 4;

@internal
extension SquadronTimeoutExceptionExt on SquadronTimeoutException {
  static SquadronTimeoutException? deserialize(List? props) {
    if (props == null) return null;
    if (props[_$type] != $timeoutExceptionType) return null;
    final microSecs = (props[_$duration] as num?)?.toInt();
    return SquadronTimeoutException(
      props[_$tokenId],
      props[_$message],
      (microSecs == null) ? null : Duration(microseconds: microSecs),
      SquadronException.loadStackTrace(props[_$stackTrace]),
    );
  }
}
