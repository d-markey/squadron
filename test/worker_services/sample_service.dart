import 'dart:async';

import 'package:squadron/squadron_service.dart';

class SampleService implements WorkerService {
  Future io({required int milliseconds}) =>
      Future.delayed(Duration(milliseconds: milliseconds));

  void cpu({required int milliseconds}) {
    final sw = Stopwatch()..start();
    while (sw.elapsedMilliseconds < milliseconds) {/* cpu */}
  }

  Future<int> delayedIdentity(int n) async {
    await Future.delayed(delay);
    return n;
  }

  Stream<int> finiteSequence(int count) async* {
    Squadron.finest('begin finiteSequence($count)');
    for (var i = 0; i <= count; i++) {
      await Future.delayed(delay);
      yield i;
    }
    Squadron.finest('end finiteSequence($count)');
  }

  Stream<int> infiniteSequence(CancellationToken token) async* {
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

  static const delay = Duration(milliseconds: 100);

  static const ioCommand = 1;
  static const cpuCommand = 2;
  static const delayedIdentityCommand = 3;
  static const finiteSequenceCommand = 4;
  static const infiniteSequenceCommand = 5;
  static const infiniteCpuCommand = 6;
  static const logCommand = 7;

  @override
  late final Map<int, CommandHandler> operations = {
    ioCommand: (r) => io(milliseconds: r.args[0]),
    cpuCommand: (r) => cpu(milliseconds: r.args[0]),
    delayedIdentityCommand: (r) => delayedIdentity(r.args[0]),
    finiteSequenceCommand: (r) => finiteSequence(r.args[0]),
    infiniteSequenceCommand: (r) => infiniteSequence(r.cancelToken!),
    infiniteCpuCommand: (r) => infiniteCpu(r.cancelToken!),
    logCommand: (r) => log()
  };
}
