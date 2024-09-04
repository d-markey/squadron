import 'dart:async';

import 'package:cancelation_token/cancelation_token.dart';
import 'package:logger/logger.dart';
import 'package:squadron/squadron.dart';

import '../classes/custom_exception.dart';
import '../classes/platform.dart';
import '../classes/test_logger.dart';
import 'biging_marshaler.dart';
import 'delays.dart';

class TestService implements WorkerService {
  static const startupOk = 0;
  static const startupThrows = 1;
  static const startupInvalid = 2;

  TestService({bool invalid = false})
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

  Future<void> io({required int ms}) =>
      Future.delayed(Duration(milliseconds: ms));

  void cpu({required int ms}) {
    final sw = Stopwatch()..start();
    while (sw.elapsedMilliseconds < ms) {/* cpu */}
  }

  Future<int> delayed(int n) async {
    await Future.delayed(TestDelays.delay);
    return n;
  }

  void throwException() => throw Exception('intentional exception');

  void throwWorkerException() =>
      throw WorkerException('intentional worker exception');

  void throwTaskTimeOutException() =>
      throw TimeoutException('intentional timeout exception');

  void throwCanceledException() =>
      throw CanceledException('intentional canceled exception');

  void throwCustomException() =>
      throw CustomException('intentional CUSTOM exception');

  FutureOr<dynamic> sendBack(dynamic data) => data;

  void missing() {}

  FutureOr<dynamic> invalidResponse() => getUnsendable();

  FutureOr<bool> ping() => true;

  Stream<int> finite(int count) async* {
    for (var i = 0; i < count; i++) {
      await Future.delayed(TestDelays.shortDelay);
      yield i;
    }
  }

  Stream<int> infinite() async* {
    int i = 0;
    while (true) {
      await Future.delayed(TestDelays.shortDelay);
      yield i;
      i++;
    }
  }

  Stream<int> clock(
      {int frequency = 1 /* Hz */, CancelationToken? token}) async* {
    var n = 0;
    final ms = 1000 ~/ frequency;
    if (ms == 0) {
      throw Exception('Frequency is too high!');
    }
    final delay = Duration(milliseconds: ms);
    while (token == null || !token.isCanceled) {
      yield n;
      n += 1;
      await Future.delayed(delay);
    }
  }

  Future<void> cancelableInfiniteCpu(CancelationToken token) async {
    bool stop = false;
    token.onCanceled.then((_) => stop = true);
    while (!stop) {
      await Future.delayed(Duration
          .zero); // necessary for the cancelation notification to come through
      for (var i = 0; i < 10000; i++) {/* cpu */}
    }
  }

  int _pendingInfiniteWithErrors = 0;

  FutureOr<int> getPendingInfiniteWithErrors() => _pendingInfiniteWithErrors;

  Stream<int> infiniteWithErrors() {
    _pendingInfiniteWithErrors++;
    late final StreamController<int> controller;
    int paused = 0;
    Completer? resumeSignal;

    void onListen() async {
      int i = 0;
      while (true) {
        if (controller.isClosed) {
          break;
        }
        final future = resumeSignal?.future;
        if (future != null) {
          await future;
        }
        controller.add(i);
        if (i > 0 && i % 2 == 0) {
          controller.addError(WorkerException('error #$i'));
        }
        i++;
        await Future.delayed(TestDelays.shortDelay);
      }
    }

    void onPause() {
      paused++;
      resumeSignal ??= Completer();
    }

    void onResume() {
      if (paused == 0) return;
      paused--;
      if (paused == 0) {
        resumeSignal!.complete();
        resumeSignal = null;
      }
    }

    void onCancel() {
      controller.close();
      _pendingInfiniteWithErrors--;
    }

    controller = StreamController(
      onListen: onListen,
      onPause: onPause,
      onResume: onResume,
      onCancel: onCancel,
    );

    return controller.stream;
  }

  FutureOr<BigInt> bigIntAdd(BigInt a, BigInt b,
          {required bool marshalIn, required bool marshalOut}) =>
      a + b;

  final bool _invalid;

  static const invalidCommand1 = -1; // command IDs must be > 0
  static const invalidCommand0 = 0; // command IDs must be > 0

  static const setLevelCommand = 1;
  static const logCommand = 2;
  static const ioCommand = 11;
  static const cpuCommand = 12;
  static const delayedCommand = 13;
  static const throwExceptionCommand = 21;
  static const throwWorkerExceptionCommand = 22;
  static const throwTaskTimeOutExceptionCommand = 23;
  static const throwCanceledExceptionCommand = 24;
  static const throwCustomExceptionCommand = 25;
  static const sendBackCommand = 31;
  static const missingCommand = 32;
  static const invalidResponseCommand = 33;
  static const pingCommand = 34;
  static const finiteCommand = 41;
  static const infiniteCommand = 42;
  static const clockCommand = 43;
  static const cancelableInfiniteCpuCommand = 44;
  static const getPendingInfiniteWithErrorsCommand = 45;
  static const infiniteWithErrorsCommand = 46;
  static const bigIntAddCommand = 51;

  @override
  late final Map<int, CommandHandler> operations = {
    if (_invalid) invalidCommand1: (r) => null,
    if (_invalid) invalidCommand0: (r) => null,
    setLevelCommand: (r) => setLevel((r.args[0] as num).toInt()),
    logCommand: (r) => log(),
    ioCommand: (r) => io(ms: (r.args[0] as num).toInt()),
    cpuCommand: (r) => cpu(ms: (r.args[0] as num).toInt()),
    delayedCommand: (r) => delayed((r.args[0] as num).toInt()),
    throwExceptionCommand: (r) => throwException(),
    throwWorkerExceptionCommand: (r) => throwWorkerException(),
    throwTaskTimeOutExceptionCommand: (r) => throwTaskTimeOutException(),
    throwCanceledExceptionCommand: (r) => throwCanceledException(),
    throwCustomExceptionCommand: (r) => throwCustomException(),
    sendBackCommand: (r) => sendBack(r.args[0]),
    invalidResponseCommand: (r) => invalidResponse(),
    /* missingCommand */
    pingCommand: (r) => ping(),
    finiteCommand: (r) => finite((r.args[0] as num).toInt()),
    infiniteCommand: (r) => infinite(),
    clockCommand: (r) =>
        clock(frequency: (r.args[0] as num).toInt(), token: r.cancelToken),
    cancelableInfiniteCpuCommand: (r) => cancelableInfiniteCpu(r.cancelToken!),
    getPendingInfiniteWithErrorsCommand: (r) => getPendingInfiniteWithErrors(),
    infiniteWithErrorsCommand: (r) => infiniteWithErrors(),
    bigIntAddCommand: (r) async {
      final marshalIn = r.args[2] as bool;
      final marshalOut = r.args[3] as bool;
      final bigIntMarshaler = BigIntMarshaler();
      final a = marshalIn ? bigIntMarshaler.unmarshal(r.args[0]) : r.args[0];
      final b = marshalIn ? bigIntMarshaler.unmarshal(r.args[1]) : r.args[1];
      final res =
          await bigIntAdd(a, b, marshalIn: marshalIn, marshalOut: marshalOut);
      return marshalOut ? bigIntMarshaler.marshal(res) : res;
    }
  };
}
