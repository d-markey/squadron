import 'dart:async';

import 'package:cancelation_token/cancelation_token.dart';
import 'package:squadron/squadron.dart';

import '_test_context.dart';
import 'biging_marshaler.dart';
import 'test_service.dart';

class TestWorkerPool extends WorkerPool<TestWorker> implements TestService {
  TestWorkerPool._(super.entryPoint, ConcurrencySettings? concurrencySettings)
      : super(
            concurrencySettings:
                concurrencySettings ?? ConcurrencySettings.fourIoThreads);

  TestWorkerPool([ConcurrencySettings? concurrencySettings])
      : this._(() => TestWorker(),
            concurrencySettings ?? ConcurrencySettings.fourIoThreads);

  TestWorkerPool.throws([ConcurrencySettings? concurrencySettings])
      : this._(() => TestWorker.throws(), concurrencySettings);

  static TestWorkerPool? missingStartRequest(
          [ConcurrencySettings? concurrencySettings]) =>
      (TestContext.entryPoints.missingStartRequest == null)
          ? null
          : TestWorkerPool._(
              () => TestWorker.missingStartRequest()!, concurrencySettings);

  TestWorkerPool.invalid([ConcurrencySettings? concurrencySettings])
      : this._(() => TestWorker.invalid(), concurrencySettings);

  @override
  Future log() => execute((w) => w.log());

  @override
  Future io({required int ms}) => execute((w) => w.io(ms: ms));

  @override
  Future cpu({required int ms}) => execute((w) => w.cpu(ms: ms));

  @override
  Future<int> delayed(int n) => execute((w) => w.delayed(n));

  @override
  Future<int> throwException() => execute((w) => w.throwException());

  @override
  Future<int> throwWorkerException() =>
      execute((w) => w.throwWorkerException());

  @override
  Future<int> throwTaskTimeOutException() =>
      execute((w) => w.throwTaskTimeOutException());

  @override
  Future<int> throwCanceledException() =>
      execute((w) => w.throwCanceledException());

  @override
  Future<int> throwCustomException() =>
      execute((w) => w.throwCustomException());

  @override
  Future<dynamic> forward(dynamic data) => execute((w) => w.forward(data));

  @override
  Future missing() => execute((w) => w.missing());

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
  Future cancelableInfiniteCpu(CancelationToken token) =>
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

  ValueTask<int> delayedIdentityTask(int n) =>
      scheduleTask((w) => w.delayed(n));

  StreamTask<int> finiteTask(int n, [CancelationToken? token]) =>
      scheduleStream((w) => w.finite(n, token));

  StreamTask<int> infiniteWithErrorsTask([CancelationToken? token]) =>
      scheduleStream((w) => w.infiniteWithErrors(token));
}

class TestWorker extends Worker implements TestService {
  TestWorker._(super.entryPoint, List args, [PlatformWorkerHook? hook])
      : super(platformWorkerHook: hook, args: args);

  TestWorker([PlatformWorkerHook? hook])
      : this._(
          TestContext.entryPoints.test,
          [TestService.startupOk],
          hook,
        );

  TestWorker.throws([PlatformWorkerHook? hook])
      : this._(
          TestContext.entryPoints.test,
          [TestService.startupThrows],
          hook,
        );

  TestWorker.invalid([PlatformWorkerHook? hook])
      : this._(
          TestContext.entryPoints.test,
          [TestService.startupInvalid],
          hook,
        );

  static TestWorker? missingStartRequest() =>
      (TestContext.entryPoints.missingStartRequest == null)
          ? null
          : TestWorker._(
              TestContext.entryPoints.missingStartRequest,
              [TestService.startupOk],
            );

  @override
  Future log() => send(TestService.logCommand);

  @override
  Future io({required int ms}) => send(TestService.ioCommand, args: [ms]);

  @override
  Future cpu({required int ms}) => send(TestService.cpuCommand, args: [ms]);

  @override
  Future<int> delayed(int n) => send(TestService.delayedCommand, args: [n]);

  @override
  Future<int> throwException() => send(TestService.throwExceptionCommand);

  @override
  Future<int> throwWorkerException() =>
      send(TestService.throwWorkerExceptionCommand);

  @override
  Future<int> throwTaskTimeOutException() =>
      send(TestService.throwTaskTimeOutExceptionCommand);

  @override
  Future<int> throwCanceledException() =>
      send(TestService.throwCanceledExceptionCommand);

  @override
  Future<int> throwCustomException() =>
      send(TestService.throwCustomExceptionCommand);

  @override
  Future<dynamic> forward(dynamic data) =>
      send(TestService.forwardCommand, args: [data]);

  @override
  Future missing() => send(TestService.missingCommand);

  @override
  Future<dynamic> invalidResponse() => send(TestService.invalidResponseCommand);

  @override
  Future<bool> ping() => send(TestService.pingCommand);

  @override
  Stream<int> finite(int count, [CancelationToken? token]) =>
      stream(TestService.finiteCommand, args: [count], token: token);

  @override
  Stream<int> infinite([CancelationToken? token]) =>
      stream(TestService.infiniteCommand, token: token);

  @override
  Stream<int> clock({int frequency = 1, CancelationToken? token}) =>
      stream(TestService.clockCommand, args: [frequency], token: token);

  @override
  Future cancelableInfiniteCpu(CancelationToken token) =>
      send(TestService.cancelableInfiniteCpuCommand, token: token);

  @override
  Future<int> getPendingInfiniteWithErrors() =>
      send(TestService.getPendingInfiniteWithErrorsCommand);

  @override
  Stream<int> infiniteWithErrors([CancelationToken? token]) =>
      stream(TestService.infiniteWithErrorsCommand, token: token);

  @override
  Future<BigInt> bigIntAdd(BigInt a, BigInt b,
      {required bool marshalIn, required bool marshalOut}) async {
    final bigIntMarshaler = BigIntMarshaler();
    final $a = marshalIn ? bigIntMarshaler.marshal(a) : a;
    final $b = marshalIn ? bigIntMarshaler.marshal(b) : b;
    final res = await send(
      TestService.bigIntAddCommand,
      args: [$a, $b, marshalIn, marshalOut],
      inspectRequest: true,
      inspectResponse: true,
    );
    return marshalOut ? bigIntMarshaler.unmarshal(res) : res;
  }
}
