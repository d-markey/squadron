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
    await Future.delayed(Duration(milliseconds: delay));
    return n;
  }

  Stream<int> delayedSequence(int count) async* {
    for (var i = 1; i <= count; i++) {
      await Future.delayed(Duration(milliseconds: delay));
      yield i;
    }
  }

  static const delay = 100;

  static const ioCommand = 1;
  static const cpuCommand = 2;
  static const delayedIdentityCommand = 3;
  static const delayedSequenceCommand = 4;

  @override
  late final Map<int, CommandHandler> operations = {
    SampleService.ioCommand: (r) => io(milliseconds: r.args[0]),
    SampleService.cpuCommand: (r) => cpu(milliseconds: r.args[0]),
    SampleService.delayedIdentityCommand: (r) => delayedIdentity(r.args[0]),
    SampleService.delayedSequenceCommand: (r) => delayedSequence(r.args[0]),
  };
}
