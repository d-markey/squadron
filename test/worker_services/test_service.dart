import 'dart:async';

import 'package:squadron/squadron_service.dart';

import '../classes/custom_exception.dart';
import '../classes/untransferable.dart';

class TestService implements WorkerService {
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
      throw TaskTimeoutException(message: 'intentional timeout exception');

  Future<int> throwCancelledException() =>
      throw CancelledException(message: 'intentional cancelled exception');

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

  Future cancellableInfiniteCpu(CancellationToken token) async {
    bool stop = false;
    token.addListener(() => stop = true);
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
      _pendingInfiniteWithErrors--;
    }

    controller = StreamController(
        onListen: onListen,
        onPause: onPause,
        onResume: onResume,
        onCancel: onCancel);

    return controller.stream;
  }

  final bool _invalid;

  static const shortDelay = Duration(milliseconds: 5);
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
  static const throwCancelledExceptionCommand = 13;
  static const throwCustomExceptionCommand = 7;
  static const forwardCommand = 8;
  static const missingCommand = 9;
  static const invalidResponseCommand = 10;
  static const pingCommand = 11;
  static const finiteCommand = 14;
  static const infiniteCommand = 15;
  static const cancellableInfiniteCpuCommand = 16;
  static const getPendingInfiniteWithErrorsCommand = 17;
  static const infiniteWithErrorsCommand = 18;

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
    throwCancelledExceptionCommand: (r) => throwCancelledException(),
    throwCustomExceptionCommand: (r) => throwCustomException(),
    forwardCommand: (r) => forward(r.args[0]),
    invalidResponseCommand: (r) => invalidResponse(),
    /* missingCommand */
    pingCommand: (r) => ping(),
    finiteCommand: (r) => finite(r.args[0]),
    infiniteCommand: (r) => infinite(),
    cancellableInfiniteCpuCommand: (r) =>
        cancellableInfiniteCpu(r.cancelToken!),
    getPendingInfiniteWithErrorsCommand: (r) => getPendingInfiniteWithErrors(),
    infiniteWithErrorsCommand: (r) => infiniteWithErrors(),
  };
}
