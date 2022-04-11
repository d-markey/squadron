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

  Stream<int> finite(int count) async* {
    for (var i = 0; i <= count; i++) {
      await Future.delayed(delay);
      yield i;
    }
  }

  Stream<int> infinite(CancellationToken token) async* {
    int i = 0;
    while (true) {
      if (token.cancelled) {
        throw CancelledException(message: token.message);
      }
      await Future.delayed(delay);
      yield i;
      i++;
    }
  }

  Future cancellableInfiniteCpu(CancellationToken token) async {
    while (true) {
      await Future(() {});
      if (token.cancelled) throw CancelledException(message: token.message);
      for (var i = 0; i < 10000; i++) {/* cpu */}
    }
  }

  Future<bool> cannotListen(CancellationToken token) async {
    try {
      token.addListener(() {}); // not available in workers
      return false;
    } catch (ex) {
      token.removeListener(() {}); // safe
      return ex is SquadronError;
    }
  }

  Stream<int> infiniteWithErrors(CancellationToken token) {
    late final StreamController<int> controller;
    int paused = 0;
    Completer? resumeSignal;

    void onListen() async {
      int i = 0;
      while (true) {
        if (controller.isClosed) {
          break;
        }
        if (token.cancelled) {
          controller.addError(CancelledException(message: token.message));
          controller.close();
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
      paused--;
      if (paused == 0) {
        resumeSignal!.complete();
        resumeSignal = null;
      }
    }

    controller = StreamController(
      onListen: onListen,
      onPause: onPause,
      onResume: onResume,
    );

    return controller.stream;
  }

  static const delay = Duration(milliseconds: 100);

  static const logCommand = 1;
  static const ioCommand = 2;
  static const cpuCommand = 3;
  static const delayedCommand = 4;
  static const finiteCommand = 5;
  static const infiniteCommand = 6;
  static const cancellableInfiniteCpuCommand = 7;
  static const cannotListenCommand = 8;
  static const infiniteWithErrorsCommand = 9;

  @override
  late final Map<int, CommandHandler> operations = {
    logCommand: (r) => log(),
    ioCommand: (r) => io(milliseconds: r.args[0]),
    cpuCommand: (r) => cpu(milliseconds: r.args[0]),
    delayedCommand: (r) => delayed(r.args[0]),
    finiteCommand: (r) => finite(r.args[0]),
    infiniteCommand: (r) => infinite(r.cancelToken!),
    cancellableInfiniteCpuCommand: (r) =>
        cancellableInfiniteCpu(r.cancelToken!),
    cannotListenCommand: (r) => cannotListen(r.cancelToken!),
    infiniteWithErrorsCommand: (r) => infiniteWithErrors(r.cancelToken!),
  };
}
