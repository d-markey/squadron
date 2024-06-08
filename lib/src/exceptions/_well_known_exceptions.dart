import 'dart:async';

import 'package:cancelation_token/cancelation_token.dart';
import 'package:meta/meta.dart';

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

@internal
extension CanceledConversionExt on CanceledException {
  SquadronException toSquadronException(
          [String? tokenId, StackTrace? stackTrace]) =>
      SquadronCanceledException.from(
        tokenId ?? '',
        this,
        stackTrace,
      );
}

@internal
extension TimeoutConversionExt on TimeoutException {
  SquadronException toSquadronException(
          [String? tokenId, StackTrace? stackTrace]) =>
      SquadronTimeoutException(
        tokenId ?? '',
        message ?? 'Operation timeout',
        duration,
        stackTrace,
      );
}
