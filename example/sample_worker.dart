import 'dart:isolate';

import 'package:squadron/squadron.dart';

class SampleWorker extends Worker {
  SampleWorker() : super(SampleWorker._main);

  @override
  final startArguments = [];

  Future<int> cpuOperation(int number) {
    return send<int>(_cpuOperation, [number]);
  }

  Future<int> ioOperation(int number) {
    return send<int>(_ioOperation, [number]);
  }

  // private implementation, this is the thread's main program
  static const _cpuOperation = 1;
  static const _ioOperation = 2;

  static void _main(List command) {
    final receiver = ReceivePort();
    WorkerRequest.fromMessage(command).connect(receiver);

    receiver.listen((command) async {
      final req = WorkerRequest.fromMessage(command);
      if (req.command == null) {
        receiver.close();
        return;
      }
      switch (req.command) {
        case _cpuOperation:
          req.reply(cpuOperationImpl(req.args[0]));
          return;
        case _ioOperation:
          req.reply(await ioOperationImpl(req.args[0]));
          return;
        default:
          req.exception(WorkerException('unknown message ${req.command}'),
              StackTrace.current);
          return;
      }
    });
  }

  static int cpuOperationImpl(int n) {
    var start = DateTime.now().millisecondsSinceEpoch;
    var elapsed = 0;
    while (elapsed < 2) {
      elapsed = DateTime.now().millisecondsSinceEpoch - start;
    }
    return n;
  }

  static Future<int> ioOperationImpl(int n) async {
    await Future.delayed(Duration(milliseconds: 2));
    return n;
  }
}
