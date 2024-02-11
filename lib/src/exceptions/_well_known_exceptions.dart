import 'dart:async';

import 'package:cancelation_token/cancelation_token.dart';

import 'squadron_canceled_exception.dart';
import 'squadron_exception.dart';
import 'squadron_timeout_exception.dart';

const $squadronErrorType = '\$sqdrn';
const $workerExceptionType = '\$wrkr';
const $canceledExceptionType = '\$cncld';
const $canceledExceptionsType = '\$cncld*';
const $timeoutExceptionType = '\$tmt';

const $reservedExceptionTypeIds = {
  $squadronErrorType,
  $workerExceptionType,
  $canceledExceptionType,
  $canceledExceptionsType,
  $timeoutExceptionType,
};

extension CanceledConversion on CanceledException {
  SquadronException toSquadronException([String? tokenId]) =>
      SquadronCanceledException.from(tokenId ?? '', this);
}

extension TimeoutConversion on TimeoutException {
  SquadronException toSquadronException([String? tokenId]) =>
      SquadronTimeoutException(
          tokenId ?? '', message ?? 'Operation timeout', duration, null);
}
