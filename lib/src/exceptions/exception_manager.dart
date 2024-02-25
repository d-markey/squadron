import 'package:meta/meta.dart';

import '_well_known_exceptions.dart';
import 'squadron_canceled_exception.dart';
import 'squadron_canceled_exceptions.dart';
import 'squadron_error.dart';
import 'squadron_exception.dart';
import 'squadron_timeout_exception.dart';
import 'worker_exception.dart';

typedef WorkerExceptionDeserializer = WorkerException? Function(List props);

@internal
typedef SquadronExceptionDeserializer = SquadronException? Function(List props);

class ExceptionManager {
  ExceptionManager();

  final _deserializers = <String, SquadronExceptionDeserializer>{
    $canceledExceptionType: SquadronCanceledException.deserialize,
    $timeoutExceptionType: SquadronTimeoutException.deserialize,
    $canceledExceptionsType: SquadronCanceledExceptions.deserialize,
    $squadronErrorType: SquadronErrorExt.deserialize,
    $workerExceptionType: WorkerException.deserialize,
  };

  /// Registers a deserializer for a custom [WorkerException]. If the deserializer is
  /// already registered, registering it again will have no effect.
  void register(
      String exceptionTypeId, WorkerExceptionDeserializer deserializer) {
    if ($reservedExceptionTypeIds.contains(exceptionTypeId)) {
      throw SquadronErrorExt.create(
          'Invalid exception type ID: $exceptionTypeId is reserved.',
          StackTrace.current);
    }
    _deserializers[exceptionTypeId] = deserializer;
  }

  /// Unregisters a deserializer that was previously registered, does nothing otherwise.
  /// Please note that for a deregistration to have an effect, the exact same instance that
  /// was provided to [register] must be provided to this method; avoid passing lambdas,
  /// prefer passing static methods or top-level functions instead.
  void unregister(String exceptionTypeId) {
    if ($reservedExceptionTypeIds.contains(exceptionTypeId)) {
      throw SquadronErrorExt.create(
          'Invalid exception type ID: $exceptionTypeId is reserved.',
          StackTrace.current);
    }
    _deserializers.remove(exceptionTypeId);
  }

  /// Deserializes a [List] that was produced by [serialize].
  SquadronException? deserialize(List? data) {
    if (data == null) {
      return null;
    }
    final exceptionType = data[0];
    SquadronException? error;
    try {
      final deserializer = _deserializers[exceptionType];
      error = deserializer?.call(data) ??
          SquadronErrorExt.create(
              'failed to deserialize exception information: $data',
              StackTrace.current);
    } catch (ex, st) {
      error = SquadronErrorExt.create(
          'failed to deserialize exception information: $ex', st);
    }
    return error;
  }
}
