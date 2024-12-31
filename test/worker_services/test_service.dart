import 'dart:async';

import 'package:cancelation_token/cancelation_token.dart';
import 'package:squadron/squadron.dart';

import 'biging_marshaler.dart';
import 'delays.dart';

class TestService implements WorkerService {
  static const startupOk = 0;
  static const startupThrows = 1;
  static const startupInvalid = 2;

  TestService({bool invalid = false})
      : _invalid = invalid,
        super() {
    operations.addAll({
      if (_invalid) invalidCommand1: (r) => null,
      if (_invalid) invalidCommand0: (r) => null,
      ioCommand: (r) => io(ms: (r.args[0] as num).toInt()),
      cpuCommand: (r) => cpu(ms: (r.args[0] as num).toInt()),
      delayedCommand: (r) => delayed((r.args[0] as num).toInt()),
      pingCommand: (r) => ping(),
      finiteCommand: (r) => finite((r.args[0] as num).toInt()),
      infiniteCommand: (r) => infinite(),
      clockCommand: (r) =>
          clock(frequency: (r.args[0] as num).toInt(), token: r.cancelToken),
      cancelableInfiniteCpuCommand: (r) =>
          cancelableInfiniteCpu(r.cancelToken!),
      getPendingInfiniteWithErrorsCommand: (r) =>
          getPendingInfiniteWithErrors(),
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
      },
      platformTypeCommand: (r) => getPlatformType().toString(),
      mapCommand: (r) =>
          map(Squadron.converter.map<String, BigInt>()(r.args[0])),
    });
  }

  Future<void> io({required int ms}) async =>
      await Future.delayed(Duration(milliseconds: ms));

  void cpu({required int ms}) {
    final sw = Stopwatch()..start();
    while (sw.elapsedMilliseconds < ms) {/* cpu */}
  }

  Future<int> delayed(int n) async {
    await Future.delayed(TestDelays.delay);
    return n;
  }

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

  FutureOr<SquadronPlatformType> getPlatformType() => Squadron.platformType;

  Future<Map<BigInt, String>> map(Map<String, BigInt> input) async =>
      input.map((k, v) => MapEntry(v, k));

  final bool _invalid;

  static const invalidCommand1 = -1; // command IDs must be > 0
  static const invalidCommand0 = 0; // command IDs must be > 0
  static const ioCommand = 11;
  static const cpuCommand = 12;
  static const delayedCommand = 13;
  static const pingCommand = 21;
  static const finiteCommand = 31;
  static const infiniteCommand = 32;
  static const clockCommand = 33;
  static const cancelableInfiniteCpuCommand = 34;
  static const getPendingInfiniteWithErrorsCommand = 35;
  static const infiniteWithErrorsCommand = 36;
  static const bigIntAddCommand = 41;
  static const platformTypeCommand = 51;
  static const mapCommand = 52;

  @override
  final Map<int, CommandHandler> operations = {};
}
