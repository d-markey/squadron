import 'dart:async';
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
  static void _main(List command) {
    final receiver = ReceivePort();
    WorkerRequest.fromMessage(command).connect(receiver);

    receiver.listen((command) async {
      WorkerRequest? req;
      try {
        req = WorkerRequest.fromMessage(command);
        if (req.command == null) {
          receiver.close();
          return;
        }
        var op = _operations[req.command];
        if (req.command == null) {
          req.exception(WorkerException('unknown command ${req.command}'),
              StackTrace.current);
          return;
        }
        req.reply(await op!(req));
      } on WorkerException catch (e, st) {
        req?.exception(e, st);
      } catch (e, st) {
        req?.exception(
            WorkerException('unexpected exception: ${e.runtimeType} => $e}',
                stackTrace: st.toString()),
            st);
      }
    });
  }

  static const _cpuOperation = 1;
  static const _ioOperation = 2;

  static final Map<int, FutureOr<dynamic> Function(WorkerRequest req)>
      _operations = {
    _cpuOperation: _cpuOperationImpl,
    _ioOperation: _ioOperationImpl,
  };

  static int _cpuOperationImpl(WorkerRequest req) =>
      cpuOperationImpl(req.args[0]);
  static Future<int> _ioOperationImpl(WorkerRequest req) =>
      ioOperationImpl(req.args[0]);

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
