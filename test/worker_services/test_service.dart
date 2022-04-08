import 'dart:async';

import 'package:squadron/squadron_service.dart';

class TestService implements WorkerService {
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
    Squadron.finest('begin finite($count)');
    for (var i = 0; i <= count; i++) {
      await Future.delayed(delay);
      yield i;
    }
    Squadron.finest('end finite($count)');
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

  Future infiniteCpu(CancellationToken token) async {
    while (true) {
      await Future(() {});
      if (token.cancelled) throw CancelledException(message: token.message);
      for (var i = 0; i < 10000; i++) {/* cpu */}
    }
  }

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

  Future<bool> cannotListen(CancellationToken token) async {
    try {
      token.addListener(() {}); // not available in workers
      return false;
    } catch (ex) {
      token.removeListener(() {}); // safe
      return ex is SquadronError;
    }
  }

  static const delay = Duration(milliseconds: 100);

  static const ioCommand = 1;
  static const cpuCommand = 2;
  static const delayedCommand = 3;
  static const finiteCommand = 4;
  static const infiniteCommand = 5;
  static const infiniteCpuCommand = 6;
  static const logCommand = 7;
  static const cannotListenCommand = 8;

  @override
  late final Map<int, CommandHandler> operations = {
    ioCommand: (r) => io(milliseconds: r.args[0]),
    cpuCommand: (r) => cpu(milliseconds: r.args[0]),
    delayedCommand: (r) => delayed(r.args[0]),
    finiteCommand: (r) => finite(r.args[0]),
    infiniteCommand: (r) => infinite(r.cancelToken!),
    infiniteCpuCommand: (r) => infiniteCpu(r.cancelToken!),
    logCommand: (r) => log(),
    cannotListenCommand: (r) => cannotListen(r.cancelToken!),
  };
}
