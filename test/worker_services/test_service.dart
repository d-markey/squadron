import 'dart:async';

import 'package:cancelation_token/cancelation_token.dart';
import 'package:squadron/squadron.dart';

import '../classes/custom_exception.dart';
import '../classes/platform.dart';
import 'biging_marshaler.dart';

class TestService implements WorkerService {
  static const startupOk = 0;
  static const startupThrows = 1;
  static const startupInvalid = 2;

  TestService({bool invalid = false})
      : _invalid = invalid,
        super();

  void log() {
    Squadron.finest('finest test in worker');
    Squadron.finer('finer test in worker');
    Squadron.fine('fine test in worker');
    Squadron.config('config test in worker');
    Squadron.info('info test in worker');
    Squadron.warning('warning test in worker');
    Squadron.severe('severe test in worker');
    Squadron.shout('shout test in worker');
  }

  Future io({required int ms}) => Future.delayed(Duration(milliseconds: ms));

  void cpu({required int ms}) {
    final sw = Stopwatch()..start();
    while (sw.elapsedMilliseconds < ms) {/* cpu */}
  }

  Future<int> delayed(int n) async {
    await Future.delayed(delay);
    return n;
  }

  FutureOr throwException() => throw Exception('intentional exception');

  FutureOr throwWorkerException() =>
      throw WorkerException('intentional worker exception');

  Future<int> throwTaskTimeOutException() =>
      throw TimeoutException('intentional timeout exception');

  Future<int> throwCanceledException() =>
      throw CanceledException('intentional canceled exception');

  FutureOr throwCustomException() =>
      throw CustomException('intentional CUSTOM exception');

  FutureOr<dynamic> forward(dynamic data) => data;

  FutureOr missing() {}

  FutureOr<dynamic> invalidResponse() => getUntransferable();

  FutureOr<bool> ping() => true;

  Stream<int> finite(int count) async* {
    for (var i = 0; i <= count; i++) {
      await Future.delayed(delay);
      yield i;
    }
  }

  Stream<int> infinite() async* {
    int i = 0;
    while (true) {
      await Future.delayed(delay);
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

  Future cancelableInfiniteCpu(CancelationToken token) async {
    bool stop = false;
    token.onCanceled.then((_) => stop = true);
    while (!stop) {
      await Future.delayed(Duration.zero);
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
        await Future.delayed(delay);
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
        onCancel: onCancel);

    return controller.stream;
  }

  FutureOr<BigInt> bigIntAdd(BigInt a, BigInt b,
          {required bool marshalIn, required bool marshalOut}) =>
      a + b;

  final bool _invalid;

  static const shortDelay = Duration(milliseconds: 10);
  static const delay = Duration(milliseconds: 50);

  static const invalidCommand1 = -1; // command IDs must be > 0
  static const invalidCommand0 = 0; // command IDs must be > 0

  static const logCommand = 1;
  static const ioCommand = 2;
  static const cpuCommand = 3;
  static const delayedCommand = 4;
  static const throwExceptionCommand = 6;
  static const throwWorkerExceptionCommand = 5;
  static const throwTaskTimeOutExceptionCommand = 12;
  static const throwCanceledExceptionCommand = 13;
  static const throwCustomExceptionCommand = 7;
  static const forwardCommand = 8;
  static const missingCommand = 9;
  static const invalidResponseCommand = 10;
  static const pingCommand = 11;
  static const finiteCommand = 14;
  static const infiniteCommand = 15;
  static const clockCommand = 16;
  static const cancelableInfiniteCpuCommand = 17;
  static const getPendingInfiniteWithErrorsCommand = 18;
  static const infiniteWithErrorsCommand = 19;
  static const bigIntAddCommand = 20;

  @override
  late final Map<int, CommandHandler> operations = {
    if (_invalid) invalidCommand1: (r) => null,
    if (_invalid) invalidCommand0: (r) => null,
    logCommand: (r) => log(),
    ioCommand: (r) => io(ms: r.args[0]),
    cpuCommand: (r) => cpu(ms: r.args[0]),
    delayedCommand: (r) => delayed(r.args[0]),
    throwExceptionCommand: (r) => throwException(),
    throwWorkerExceptionCommand: (r) => throwWorkerException(),
    throwTaskTimeOutExceptionCommand: (r) => throwTaskTimeOutException(),
    throwCanceledExceptionCommand: (r) => throwCanceledException(),
    throwCustomExceptionCommand: (r) => throwCustomException(),
    forwardCommand: (r) => forward(r.args[0]),
    invalidResponseCommand: (r) => invalidResponse(),
    /* missingCommand */
    pingCommand: (r) => ping(),
    finiteCommand: (r) => finite(r.args[0]),
    infiniteCommand: (r) => infinite(),
    clockCommand: (r) => clock(frequency: r.args[0], token: r.cancelToken),
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
