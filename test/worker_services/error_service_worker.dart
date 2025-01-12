import 'dart:async';

import 'package:squadron/squadron.dart';

import '../src/test_context.dart';
import 'error_service.dart';
import 'squadron_version.dart';

base class ErrorWorkerPool extends WorkerPool<ErrorWorker>
    with PoolVersion<ErrorWorker>
    implements ErrorService {
  ErrorWorkerPool._(
      super._workerFactory, ConcurrencySettings? concurrencySettings,
      [ExceptionManager? exceptionManager])
      : super(
          concurrencySettings:
              concurrencySettings ?? ConcurrencySettings.fourIoThreads,
          exceptionManager: exceptionManager,
        );

  ErrorWorkerPool(TestContext context,
      [ConcurrencySettings? concurrencySettings,
      ExceptionManager? exceptionManager])
      : this._(
          (ExceptionManager exceptionManager) =>
              ErrorWorker(context, exceptionManager: exceptionManager),
          concurrencySettings ?? ConcurrencySettings.fourIoThreads,
          exceptionManager,
        );

  ErrorWorkerPool.throws(TestContext context,
      [ConcurrencySettings? concurrencySettings,
      ExceptionManager? exceptionManager])
      : this._(
          (ExceptionManager exceptionManager) =>
              ErrorWorker.throws(context, exceptionManager: exceptionManager),
          concurrencySettings,
          exceptionManager,
        );

  ErrorWorkerPool.missingStartRequest(TestContext context,
      [ConcurrencySettings? concurrencySettings,
      ExceptionManager? exceptionManager])
      : this._(
          (ExceptionManager exceptionManager) =>
              ErrorWorker.missingStartRequest(context,
                  exceptionManager: exceptionManager),
          concurrencySettings,
          exceptionManager,
        );

  ErrorWorkerPool.invalid(TestContext context,
      [ConcurrencySettings? concurrencySettings,
      ExceptionManager? exceptionManager])
      : this._(
          (ExceptionManager exceptionManager) =>
              ErrorWorker.invalid(context, exceptionManager: exceptionManager),
          concurrencySettings,
          exceptionManager,
        );

  @override
  Future<void> setLevel(int level) => execute((w) => w.setLevel(level));

  @override
  Future<void> log() => execute((w) => w.log());

  @override
  Future<bool> ping([Object? data]) => execute((w) => w.ping(data));

  @override
  Future<void> throwException() => execute((w) => w.throwException());

  @override
  Future<void> throwWorkerException() =>
      execute((w) => w.throwWorkerException());

  @override
  Future<void> throwTaskTimeOutException() =>
      execute((w) => w.throwTaskTimeOutException());

  @override
  Future<void> throwCanceledException() =>
      execute((w) => w.throwCanceledException());

  @override
  Future<void> throwTestException() => execute((w) => w.throwTestException());

  @override
  Future<void> missing() => execute((w) => w.missing());

  @override
  Future<dynamic> invalidResponse() => execute((w) => w.invalidResponse());
}

base class ErrorWorker extends Worker
    with WorkerVersion
    implements ErrorService {
  ErrorWorker._(super.entryPoint, List args, PlatformThreadHook? hook,
      ExceptionManager? exceptionManager)
      : super(
          threadHook: hook,
          args: args,
          exceptionManager: exceptionManager,
        );

  ErrorWorker(TestContext context,
      {PlatformThreadHook? hook, ExceptionManager? exceptionManager})
      : this._(
          context.entryPoints.errors!,
          [ErrorService.startupOk],
          hook,
          exceptionManager,
        );

  ErrorWorker.throws(TestContext context,
      {PlatformThreadHook? hook, ExceptionManager? exceptionManager})
      : this._(
          context.entryPoints.errors!,
          [ErrorService.startupThrows],
          hook,
          exceptionManager,
        );

  ErrorWorker.invalid(TestContext context,
      {PlatformThreadHook? hook, ExceptionManager? exceptionManager})
      : this._(
          context.entryPoints.errors!,
          [ErrorService.startupInvalid],
          hook,
          exceptionManager,
        );

  ErrorWorker.missingStartRequest(TestContext context,
      {PlatformThreadHook? hook, ExceptionManager? exceptionManager})
      : this._(
          context.entryPoints.missingStartRequest!,
          [ErrorService.startupOk],
          hook,
          exceptionManager,
        );

  @override
  Future<void> setLevel(int level) =>
      send(ErrorService.setLevelCommand, args: [level]);

  @override
  Future<void> log() => send(ErrorService.logCommand);

  @override
  Future<bool> ping([Object? data]) =>
      send(ErrorService.pingCommand, args: [data])
          .then(Squadron.converter.value<bool>());

  @override
  Future<int> throwException() => send(ErrorService.throwExceptionCommand)
      .then(Squadron.converter.value<int>());

  @override
  Future<int> throwWorkerException() =>
      send(ErrorService.throwWorkerExceptionCommand)
          .then(Squadron.converter.value<int>());

  @override
  Future<int> throwTaskTimeOutException() =>
      send(ErrorService.throwTaskTimeOutExceptionCommand)
          .then(Squadron.converter.value<int>());

  @override
  Future<int> throwCanceledException() =>
      send(ErrorService.throwCanceledExceptionCommand)
          .then(Squadron.converter.value<int>());

  @override
  Future<int> throwTestException() =>
      send(ErrorService.throwTestExceptionCommand)
          .then(Squadron.converter.value<int>());

  @override
  Future<void> missing() => send(ErrorService.missingCommand);

  @override
  Future<dynamic> invalidResponse() =>
      send(ErrorService.invalidResponseCommand);
}
