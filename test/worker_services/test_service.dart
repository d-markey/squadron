import 'dart:async';
import 'dart:typed_data';

import 'package:cancelation_token/cancelation_token.dart';
import 'package:squadron/squadron.dart';

import '../test_constants.dart';
import 'fraction.dart';
import 'squadron_version.dart';

class TestService with SquadronVersion implements WorkerService {
  static const startupOk = 0;
  static const startupThrows = 1;
  static const startupInvalid = 2;

  TestService({bool invalid = false}) : _invalid = invalid;

  Future<void> io({required int ms}) async =>
      await Future.delayed(Duration(milliseconds: ms));

  void cpu({required int ms}) {
    final sw = Stopwatch()..start();
    while (sw.elapsedMilliseconds < ms) {/* cpu */}
  }

  Future<int> delayed(int n) async {
    await Future.delayed(delay_80ms);
    return n;
  }

  FutureOr<bool> ping() => true;

  Stream<int> finite(int count) async* {
    for (var i = 0; i < count; i++) {
      await Future.delayed(delay_20ms);
      yield i;
    }
  }

  Stream<int> infinite() async* {
    int i = 0;
    while (true) {
      await Future.delayed(delay_20ms);
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
        await Future.delayed(delay_20ms);
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

  FutureOr<Fraction> fractionAdd(Fraction a, Fraction b,
          {required bool marshalIn, required bool marshalOut}) =>
      a + b;

  FutureOr<SquadronPlatformType> getPlatformType() => Squadron.platformType;

  Future<Map<BigInt, String>> map(Map<String, BigInt> input) async =>
      input.map((k, v) => MapEntry(v, k));

  Future<Set<BigInt>> set(Set<BigInt> input) async =>
      input.map((v) => v * BigInt.two).toSet();

  Future<bool> checkBuffers(TypedData a, TypedData b) async =>
      identical(a.buffer, b.buffer);

  Future<bool> checkFractions(Fraction a, Fraction b) async => identical(a, b);

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
  static const fractionAddCommand = 41;
  static const platformTypeCommand = 51;
  static const mapCommand = 52;
  static const setCommand = 53;
  static const checkBufferCommand = 61;
  static const checkFractionCommand = 62;

  @override
  late final operations = OperationsMap({
    if (_invalid) invalidCommand1: (r) => null,
    if (_invalid) invalidCommand0: (r) => null,
    SquadronVersion.versionCommand: (r) => getVersion(),
    ioCommand: (r) => io(ms: (r.args[0] as num).toInt()),
    cpuCommand: (r) => cpu(ms: (r.args[0] as num).toInt()),
    delayedCommand: (r) => delayed((r.args[0] as num).toInt()),
    pingCommand: (r) => ping(),
    finiteCommand: (r) => finite((r.args[0] as num).toInt()),
    infiniteCommand: (r) => infinite(),
    clockCommand: (r) =>
        clock(frequency: (r.args[0] as num).toInt(), token: r.cancelToken),
    cancelableInfiniteCpuCommand: (r) => cancelableInfiniteCpu(r.cancelToken!),
    getPendingInfiniteWithErrorsCommand: (r) => getPendingInfiniteWithErrors(),
    infiniteWithErrorsCommand: (r) => infiniteWithErrors(),
    fractionAddCommand: (r) async {
      final cin = MarshalingContext();
      final marshalIn = cin.value<bool>()(r.args[2]);
      final marshalOut = cin.value<bool>()(r.args[3]);
      final toListOfInts = cin.list<int>();
      final toFraction = cin.value<Fraction>();
      final fractionMarshaler = const FractionMarshaler();
      final a = marshalIn
          ? fractionMarshaler.unmarshal(toListOfInts(r.args[0]), cin)
          : toFraction(r.args[0]);
      final b = marshalIn
          ? fractionMarshaler.unmarshal(toListOfInts(r.args[1]), cin)
          : toFraction(r.args[1]);
      final res =
          await fractionAdd(a, b, marshalIn: marshalIn, marshalOut: marshalOut);
      final cout = MarshalingContext();
      return marshalOut
          ? fractionMarshaler.marshal(res, cout)
          : toFraction(res);
    },
    platformTypeCommand: (r) => getPlatformType().toString(),
    mapCommand: (r) => map(Squadron.converter.map<String, BigInt>()(r.args[0])),
    setCommand: (r) => set(Squadron.converter.set<BigInt>()(r.args[0])),
    checkBufferCommand: (r) => checkBuffers(r.args[0], r.args[1]),
    checkFractionCommand: (r) {
      final cin = MarshalingContext();
      final toListOfInt = cin.list<int>();
      final marshaler = const FractionMarshaler();
      return checkFractions(
        marshaler.unmarshal(toListOfInt(r.args[0]), cin),
        marshaler.unmarshal(toListOfInt(r.args[1]), cin),
      );
    },
  });
}
