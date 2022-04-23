import 'dart:async';

import 'package:squadron/squadron_service.dart';

class TestService implements WorkerService {
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

  Future io({required int milliseconds}) =>
      Future.delayed(Duration(milliseconds: milliseconds));

  void cpu({required int milliseconds}) {
    final sw = Stopwatch()..start();
    while (sw.elapsedMilliseconds < milliseconds) {/* cpu */}
  }

  Future<int> delayed(int n) async {
    await Future.delayed(delay);
    return n;
  }

  Future<int> timeOut() async {
    await Future.delayed(delay);
    throw TaskTimeoutException(message: 'intentional timeout exception');
  }

  Future<int> cancelled() async {
    await Future.delayed(delay);
    throw CancelledException(message: 'intentional cancelled exception');
  }

  Stream<int> finite(int count) async* {
    for (var i = 0; i <= count; i++) {
      await Future.delayed(delay);
      yield i;
    }
  }

  Stream<int> infinite(CancellationToken token) async* {
    bool stop = false;
    token.addListener(() => stop = true);
    int i = 0;
    while (!stop) {
      await Future.delayed(delay);
      yield i;
      i++;
    }
  }

  Future cancellableInfiniteCpu(CancellationToken token) async {
    bool stop = false;
    token.addListener(() => stop = true);
    while (!stop) {
      await Future(() {});
      for (var i = 0; i < 10000; i++) {/* cpu */}
    }
  }

  int _pendingInfiniteWithErrors = 0;

  FutureOr<int> getPendingInfiniteWithErrors() => _pendingInfiniteWithErrors;

  Stream<int> infiniteWithErrors(CancellationToken token) {
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

  static const delay = Duration(milliseconds: 50);

  static const logCommand = 1;
  static const ioCommand = 2;
  static const cpuCommand = 3;
  static const delayedCommand = 4;
  static const timeOutCommand = 5;
  static const cancelCommand = 6;
  static const finiteCommand = 7;
  static const infiniteCommand = 8;
  static const cancellableInfiniteCpuCommand = 9;
  static const getPendingInfiniteWithErrorsCommand = 10;
  static const infiniteWithErrorsCommand = 11;

  @override
  late final Map<int, CommandHandler> operations = {
    logCommand: (r) => log(),
    ioCommand: (r) => io(milliseconds: r.args[0]),
    cpuCommand: (r) => cpu(milliseconds: r.args[0]),
    delayedCommand: (r) => delayed(r.args[0]),
    timeOutCommand: (r) => timeOut(),
    cancelCommand: (r) => cancelled(),
    finiteCommand: (r) => finite(r.args[0]),
    infiniteCommand: (r) => infinite(r.cancelToken!),
    cancellableInfiniteCpuCommand: (r) =>
        cancellableInfiniteCpu(r.cancelToken!),
    getPendingInfiniteWithErrorsCommand: (r) => getPendingInfiniteWithErrors(),
    infiniteWithErrorsCommand: (r) => infiniteWithErrors(r.cancelToken!),
  };
}
