import 'dart:async';

import 'package:cancelation_token/cancelation_token.dart';
import 'package:squadron/squadron.dart';

import '../classes/test_context.dart';
import 'biging_marshaler.dart';
import 'test_service.dart';

base class TestWorkerPool extends WorkerPool<TestWorker>
    implements TestService {
  TestWorkerPool._(
      super._workerFactory, ConcurrencySettings? concurrencySettings,
      [ExceptionManager? exceptionManager])
      : super(
          concurrencySettings:
              concurrencySettings ?? ConcurrencySettings.fourIoThreads,
          exceptionManager: exceptionManager,
        );

  TestWorkerPool(TestContext context,
      [ConcurrencySettings? concurrencySettings,
      ExceptionManager? exceptionManager])
      : this._(
          (ExceptionManager exceptionManager) =>
              TestWorker(context, exceptionManager: exceptionManager),
          concurrencySettings ?? ConcurrencySettings.fourIoThreads,
          exceptionManager,
        );

  TestWorkerPool.throws(TestContext context,
      [ConcurrencySettings? concurrencySettings,
      ExceptionManager? exceptionManager])
      : this._(
          (ExceptionManager exceptionManager) =>
              TestWorker.throws(context, exceptionManager: exceptionManager),
          concurrencySettings,
          exceptionManager,
        );

  TestWorkerPool.missingStartRequest(TestContext context,
      [ConcurrencySettings? concurrencySettings,
      ExceptionManager? exceptionManager])
      : this._(
          (ExceptionManager exceptionManager) => TestWorker.missingStartRequest(
              context,
              exceptionManager: exceptionManager),
          concurrencySettings,
          exceptionManager,
        );

  TestWorkerPool.invalid(TestContext context,
      [ConcurrencySettings? concurrencySettings,
      ExceptionManager? exceptionManager])
      : this._(
          (ExceptionManager exceptionManager) =>
              TestWorker.invalid(context, exceptionManager: exceptionManager),
          concurrencySettings,
          exceptionManager,
        );

  @override
  Future<void> setLevel(int level) => execute((w) => w.setLevel(level));

  @override
  Future<void> log() => execute((w) => w.log());

  @override
  Future<void> io({required int ms}) => execute((w) => w.io(ms: ms));

  @override
  Future<void> cpu({required int ms}) => execute((w) => w.cpu(ms: ms));

  @override
  Future<int> delayed(int n) => execute((w) => w.delayed(n));

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
  Future<void> throwCustomException() =>
      execute((w) => w.throwCustomException());

  @override
  Future<dynamic> sendBack(dynamic data) => execute((w) => w.sendBack(data));

  @override
  Future<void> missing() => execute((w) => w.missing());

  @override
  Future<dynamic> invalidResponse() => execute((w) => w.invalidResponse());

  @override
  Future<bool> ping() => execute((w) => w.ping());

  @override
  Stream<int> finite(int count, [CancelationToken? token]) =>
      stream((w) => w.finite(count, token));

  @override
  Stream<int> infinite([CancelationToken? token]) =>
      stream((w) => w.infinite(token));

  @override
  Stream<int> clock({int frequency = 1, CancelationToken? token}) =>
      stream((w) => w.clock(frequency: frequency, token: token));

  @override
  Future<int> cancelableInfiniteCpu(CancelationToken token) =>
      execute((w) => w.cancelableInfiniteCpu(token));

  @override
  Future<int> getPendingInfiniteWithErrors() => (maxWorkers == 1)
      ? execute((w) => w.getPendingInfiniteWithErrors())
      : throw WorkerException(
          'getPendingInfiniteWithErrors() is not supported for worker pools with maxWorker != 1');

  @override
  Stream<int> infiniteWithErrors([CancelationToken? token]) =>
      stream((w) => w.infiniteWithErrors(token));

  @override
  Future<BigInt> bigIntAdd(BigInt a, BigInt b,
          {required bool marshalIn, required bool marshalOut}) =>
      execute((w) =>
          w.bigIntAdd(a, b, marshalIn: marshalIn, marshalOut: marshalOut));

  ValueTask<int> delayedTask(int n) => scheduleValueTask((w) => w.delayed(n));

  StreamTask<int> finiteTask(int n, [CancelationToken? token]) =>
      scheduleStreamTask((w) => w.finite(n, token));

  StreamTask<int> infiniteWithErrorsTask([CancelationToken? token]) =>
      scheduleStreamTask((w) => w.infiniteWithErrors(token));

  @override
  Future<SquadronPlatformType> getPlatformType() =>
      execute((w) => w.getPlatformType());
}

base class TestWorker extends Worker implements TestService {
  TestWorker._(super.entryPoint, List args, PlatformThreadHook? hook,
      ExceptionManager? exceptionManager)
      : super(
          threadHook: hook,
          args: args,
          exceptionManager: exceptionManager,
        );

  TestWorker(TestContext context,
      {PlatformThreadHook? hook, ExceptionManager? exceptionManager})
      : this._(
          context.entryPoints.test!,
          [TestService.startupOk],
          hook,
          exceptionManager,
        );

  TestWorker.throws(TestContext context,
      {PlatformThreadHook? hook, ExceptionManager? exceptionManager})
      : this._(
          context.entryPoints.test!,
          [TestService.startupThrows],
          hook,
          exceptionManager,
        );

  TestWorker.invalid(TestContext context,
      {PlatformThreadHook? hook, ExceptionManager? exceptionManager})
      : this._(
          context.entryPoints.test!,
          [TestService.startupInvalid],
          hook,
          exceptionManager,
        );

  TestWorker.missingStartRequest(TestContext context,
      {PlatformThreadHook? hook, ExceptionManager? exceptionManager})
      : this._(
          context.entryPoints.missingStartRequest!,
          [TestService.startupOk],
          hook,
          exceptionManager,
        );

  @override
  Future<void> setLevel(int level) =>
      send(TestService.setLevelCommand, args: [level]);

  @override
  Future<void> log() => send(TestService.logCommand);

  @override
  Future<void> io({required int ms}) => send(TestService.ioCommand, args: [ms]);

  @override
  Future<void> cpu({required int ms}) =>
      send(TestService.cpuCommand, args: [ms]);

  @override
  Future<int> delayed(int n) => send(TestService.delayedCommand, args: [n])
      .then(Squadron.converter.value<int>());

  @override
  Future<int> throwException() => send(TestService.throwExceptionCommand)
      .then(Squadron.converter.value<int>());

  @override
  Future<int> throwWorkerException() =>
      send(TestService.throwWorkerExceptionCommand)
          .then(Squadron.converter.value<int>());

  @override
  Future<int> throwTaskTimeOutException() =>
      send(TestService.throwTaskTimeOutExceptionCommand)
          .then(Squadron.converter.value<int>());

  @override
  Future<int> throwCanceledException() =>
      send(TestService.throwCanceledExceptionCommand)
          .then(Squadron.converter.value<int>());

  @override
  Future<int> throwCustomException() =>
      send(TestService.throwCustomExceptionCommand)
          .then(Squadron.converter.value<int>());

  @override
  Future<dynamic> sendBack(dynamic data) =>
      send(TestService.sendBackCommand, args: [data]);

  @override
  Future<void> missing() => send(TestService.missingCommand);

  @override
  Future<dynamic> invalidResponse() => send(TestService.invalidResponseCommand);

  @override
  Future<bool> ping() =>
      send(TestService.pingCommand).then(Squadron.converter.value<bool>());

  @override
  Stream<int> finite(int count, [CancelationToken? token]) =>
      stream(TestService.finiteCommand, args: [count], token: token)
          .map(Squadron.converter.value<int>());

  @override
  Stream<int> infinite([CancelationToken? token]) =>
      stream(TestService.infiniteCommand, token: token)
          .map(Squadron.converter.value<int>());

  @override
  Stream<int> clock({int frequency = 1, CancelationToken? token}) =>
      stream(TestService.clockCommand, args: [frequency], token: token)
          .map(Squadron.converter.value<int>());

  @override
  Future<int> cancelableInfiniteCpu(CancelationToken token) =>
      send(TestService.cancelableInfiniteCpuCommand, token: token)
          .then(Squadron.converter.value<int>());

  @override
  Future<int> getPendingInfiniteWithErrors() =>
      send(TestService.getPendingInfiniteWithErrorsCommand)
          .then(Squadron.converter.value<int>());

  @override
  Stream<int> infiniteWithErrors([CancelationToken? token]) =>
      stream(TestService.infiniteWithErrorsCommand, token: token)
          .map(Squadron.converter.value<int>());

  static final bigIntMarshaler = ((x) => (const BigIntMarshaler()).marshal(x));
  static final bigIntUnmarshaler =
      ((x) => (const BigIntMarshaler()).unmarshal(x));

  @override
  Future<BigInt> bigIntAdd(BigInt a, BigInt b,
      {required bool marshalIn, required bool marshalOut}) {
    final marshal =
        marshalIn ? bigIntMarshaler : Squadron.converter.value<BigInt>();
    return send(
      TestService.bigIntAddCommand,
      args: [marshal(a), marshal(b), marshalIn, marshalOut],
      inspectRequest: true,
      inspectResponse: true,
    ).then(
      marshalOut ? bigIntUnmarshaler : Squadron.converter.value<BigInt>(),
    );
  }

  @override
  Future<SquadronPlatformType> getPlatformType() =>
      send(TestService.platformTypeCommand).then((res) =>
          SquadronPlatformType.tryParse(
              Squadron.converter.value<String>()(res))!);
}
