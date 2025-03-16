import 'dart:async';

import 'package:cancelation_token/cancelation_token.dart';
import 'package:logger/logger.dart';
import 'package:squadron/squadron.dart';

import '../src/platform.dart';
import '../src/test_logger.dart';
import '../test_exception.dart';
import 'squadron_version.dart';

class ErrorService with SquadronVersion implements WorkerService {
  static const startupOk = 0;
  static const startupThrows = 1;
  static const startupInvalid = 2;

  ErrorService({bool invalid = false})
      : _invalid = invalid,
        super();

  final _logger = TestLogger(ProductionFilter());

  void setLevel(int level) {
    _logger.level = Level.values.where((l) => l.value == level).first;
  }

  void log() {
    _logger.t('trace test in worker');
    _logger.d('debug test in worker');
    _logger.i('info test in worker');
    _logger.w('warning test in worker');
    _logger.e('error test in worker');
    _logger.f('fatal test in worker');
  }

  FutureOr<bool> ping([Object? data]) => true;

  void throwException() => throw Exception('intentional exception');

  void throwWorkerException() =>
      throw WorkerException('intentional worker exception');

  void throwTaskTimeOutException() =>
      throw TimeoutException('intentional timeout exception');

  void throwCanceledException() =>
      throw CanceledException('intentional canceled exception');

  void throwTestException() =>
      throw TestException('intentional TEST exception');

  FutureOr<dynamic> invalidResponse() => unsendable;

  void missing() {}

  final bool _invalid;

  static const invalidCommand1 = -1; // command IDs must be > 0
  static const invalidCommand0 = 0; // command IDs must be > 0
  static const setLevelCommand = 1;
  static const logCommand = 2;
  static const pingCommand = 3;
  static const throwExceptionCommand = 11;
  static const throwWorkerExceptionCommand = 12;
  static const throwTaskTimeOutExceptionCommand = 13;
  static const throwCanceledExceptionCommand = 14;
  static const throwTestExceptionCommand = 15;
  static const missingCommand = 21;
  static const invalidResponseCommand = 22;

  OperationsMap? _operations;

  @override
  OperationsMap get operations => (_operations ??= OperationsMap({
        SquadronVersion.versionCommand: (r) => getVersion(),
        if (_invalid) invalidCommand1: (r) => null,
        if (_invalid) invalidCommand0: (r) => null,
        setLevelCommand: (r) => setLevel((r.args[0] as num).toInt()),
        logCommand: (r) => log(),
        throwExceptionCommand: (r) => throwException(),
        throwWorkerExceptionCommand: (r) => throwWorkerException(),
        throwTaskTimeOutExceptionCommand: (r) => throwTaskTimeOutException(),
        throwCanceledExceptionCommand: (r) => throwCanceledException(),
        throwTestExceptionCommand: (r) => throwTestException(),
        invalidResponseCommand: (r) => invalidResponse(),
        /* missingCommand */
        pingCommand: (r) => ping(),
      }));
}
