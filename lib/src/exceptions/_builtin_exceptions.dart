import 'dart:async';

import 'package:cancelation_token/cancelation_token.dart';
import 'package:meta/meta.dart';

import 'squadron_canceled_exception.dart';
import 'squadron_canceled_exceptions.dart';
import 'squadron_error.dart';
import 'squadron_exception.dart';
import 'squadron_timeout_exception.dart';
import 'task_canceled_exception.dart';
import 'task_terminated_exception.dart';
import 'worker_exception.dart';

const $squadronErrorType = '\$!';
const $workerExceptionType = '\$#';
const $canceledExceptionType = '\$C';
const $canceledExceptionsType = '\$C*';
const $taskCanceledExceptionType = '\$C1';
const $taskTerminatedExceptionType = '\$K';
const $timeoutExceptionType = '\$T';

@internal
typedef SquadronExceptionDeserializer = SquadronException? Function(List props);

@internal
final builtinExceptions = <String, SquadronExceptionDeserializer>{
  $canceledExceptionType: SquadronCanceledExceptionExt.deserialize,
  $timeoutExceptionType: SquadronTimeoutExceptionExt.deserialize,
  $canceledExceptionsType: SquadronCanceledExceptionsExt.deserialize,
  $taskCanceledExceptionType: TaskCanceledExceptionExt.deserialize,
  $taskTerminatedExceptionType: TaskTerminatedExceptionExt.deserialize,
  $squadronErrorType: SquadronErrorImpl.deserialize,
  $workerExceptionType: WorkerExceptionImpl.deserialize,
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
