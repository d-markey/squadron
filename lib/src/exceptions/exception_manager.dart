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
    $canceledExceptionType: SquadronCanceledExceptionExt.deserialize,
    $timeoutExceptionType: SquadronTimeoutExceptionExt.deserialize,
    $canceledExceptionsType: SquadronCanceledExceptionsExt.deserialize,
    $squadronErrorType: SquadronErrorExt.deserialize,
    $workerExceptionType: WorkerExceptionExt.deserialize,
  };

  /// Registers a deserializer for a custom [WorkerException]. If the deserializer is
  /// already registered, registering it again will have no effect.
  void register(
      String exceptionTypeId, WorkerExceptionDeserializer deserializer) {
    if ($reservedExceptionTypeIds.contains(exceptionTypeId)) {
      throw SquadronErrorExt.create(
        'Invalid exception type ID: $exceptionTypeId is reserved.',
      );
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
      );
    }
    _deserializers.remove(exceptionTypeId);
  }

  /// Deserializes a [List] that was produced by [serialize].
  SquadronException? deserialize(List? data) {
    if (data == null || data.isEmpty) {
      return null;
    }
    try {
      final exceptionType = data[0];
      final deserializer = _deserializers[exceptionType];
      return deserializer?.call(data) ??
          SquadronErrorExt.create(
            'Failed to deserialize exception information for $exceptionType: $data',
          );
    } catch (ex, st) {
      return SquadronException.from(ex, st);
    }
  }
}
