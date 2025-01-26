import 'dart:async';
import 'dart:typed_data';

import 'package:cancelation_token/cancelation_token.dart';
import 'package:squadron/squadron.dart';

import '../fraction.dart';
import '../src/test_context.dart';
import 'squadron_version.dart';
import 'test_service.dart';

base class TestWorkerPool extends WorkerPool<TestWorker>
    with PoolVersion<TestWorker>
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
  Future<void> io({required int ms}) => execute((w) => w.io(ms: ms));

  @override
  Future<void> cpu({required int ms}) => execute((w) => w.cpu(ms: ms));

  @override
  Future<int> delayed(int n) => execute((w) => w.delayed(n));

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
  Future<Fraction> fractionAdd(Fraction a, Fraction b,
          {required bool marshalIn, required bool marshalOut}) =>
      execute((w) =>
          w.fractionAdd(a, b, marshalIn: marshalIn, marshalOut: marshalOut));

  ValueTask<int> delayedTask(int n) => scheduleValueTask((w) => w.delayed(n));

  StreamTask<int> finiteTask(int n, [CancelationToken? token]) =>
      scheduleStreamTask((w) => w.finite(n, token));

  StreamTask<int> infiniteWithErrorsTask([CancelationToken? token]) =>
      scheduleStreamTask((w) => w.infiniteWithErrors(token));

  @override
  Future<SquadronPlatformType> getPlatformType() =>
      execute((w) => w.getPlatformType());

  @override
  Future<Map<BigInt, String>> map(Map<String, BigInt> input) =>
      execute((w) => w.map(input));

  @override
  Future<Set<BigInt>> set(Set<BigInt> input) => execute((w) => w.set(input));

  @override
  Future<bool> checkBuffers(TypedData a, TypedData b) =>
      execute((w) => w.checkBuffers(a, b));

  @override
  Future<bool> checkFractions(Fraction a, Fraction b) =>
      execute((w) => w.checkFractions(a, b));
}

base class TestWorker extends Worker with WorkerVersion implements TestService {
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
  Future<void> io({required int ms}) => send(TestService.ioCommand, args: [ms]);

  @override
  Future<void> cpu({required int ms}) =>
      send(TestService.cpuCommand, args: [ms]);

  @override
  Future<int> delayed(int n) => send(TestService.delayedCommand, args: [n])
      .then(Squadron.converter.value<int>());

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

  static final fractionMarshaler =
      ((x) => (const FractionMarshaler()).marshal(x));
  static final fractionUnmarshaler = ((x) =>
      (const FractionMarshaler()).unmarshal(Squadron.converter.list<int>()(x)));

  @override
  Future<Fraction> fractionAdd(Fraction a, Fraction b,
      {required bool marshalIn, required bool marshalOut}) {
    final marshal =
        marshalIn ? fractionMarshaler : Squadron.converter.value<Fraction>();
    return send(
      TestService.fractionAddCommand,
      args: [marshal(a), marshal(b), marshalIn, marshalOut],
      inspectRequest: true,
      inspectResponse: true,
    ).then(
      marshalOut ? fractionUnmarshaler : Squadron.converter.value<Fraction>(),
    );
  }

  @override
  Future<Map<BigInt, String>> map(Map<String, BigInt> input) =>
      send(TestService.mapCommand, args: [input])
          .then(Squadron.converter.map<BigInt, String>());

  @override
  Future<Set<BigInt>> set(Set<BigInt> input) =>
      send(TestService.setCommand, args: [input])
          .then(Squadron.converter.set<BigInt>());

  @override
  Future<bool> checkBuffers(TypedData a, TypedData b) =>
      send(TestService.checkBufferCommand, args: [a, b])
          .then(Squadron.converter.value<bool>());

  @override
  Future<bool> checkFractions(Fraction a, Fraction b) =>
      send(TestService.checkFractionCommand, args: [
        const FractionMarshaler().marshal(a),
        const FractionMarshaler().marshal(b),
      ]).then(Squadron.converter.value<bool>());

  @override
  Future<SquadronPlatformType> getPlatformType() =>
      send(TestService.platformTypeCommand).then((res) =>
          SquadronPlatformType.tryParse(
              Squadron.converter.value<String>()(res))!);
}
