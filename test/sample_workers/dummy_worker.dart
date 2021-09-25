import 'dart:isolate';

import 'package:squadron/squadron.dart';

class DummyWorker extends Worker {
  DummyWorker() : super(DummyWorker._main);

  @override
  final startArguments = List.empty();

  Future<dynamic> wait({ required int milliseconds }) {
    return send(_wait, [ milliseconds ]);
  }

  // private implementation, this is the thread's main program
  static const _wait = 1;

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
        case _wait:
          await Future.delayed(Duration(milliseconds: req.args[0]));
          req.reply();
          return;
        default:
          req.exception(WorkerException('unknown message ${req.command}'), StackTrace.current);
          return;
      }
    });
  }
}
