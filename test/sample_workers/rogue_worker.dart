import 'dart:isolate';

import 'package:squadron/squadron.dart';

class RogueWorker extends Worker {
  RogueWorker() : super(RogueWorker._main);

  @override
  final startArguments = List.empty();

  Future<String> throwWorkerException() {
    return send<String>(_throwWorkerException);
  }

  Future<String> throwException() {
    return send<String>(_throwException);
  }

  // private implementation, this is the thread's main program
  static const _throwWorkerException = 1;
  static const _throwException = 2;

  static void _main(List command) {
    final receiver = ReceivePort();
    WorkerRequest.fromMessage(command).connect(receiver);

    receiver.listen((command) async {
      final req = WorkerRequest.fromMessage(command);
      try {
        if (req.command == null) {
          receiver.close();
          return;
        }
        switch (req.command) {
          case _throwWorkerException:
            req.reply(await _throwWorkerExceptionImpl());
            return;
          case _throwException:
            req.reply(await _throwExceptionImpl());
            return;
          default:
            throw WorkerException('unknown command ${req.command}');
        }
      } on WorkerException catch (e, st) {
        req.exception(e, st);
      } catch (e, st) {
        req.exception(
            WorkerException('unexpected exception: ${e.runtimeType} => $e}',
                stackTrace: st.toString()),
            st);
      }
    });
  }

  static Future<String> _throwWorkerExceptionImpl() async {
    await Future.delayed(Duration(milliseconds: 5));
    throw WorkerException('expected',
        stackTrace: StackTrace.current.toString());
  }

  static Future<String> _throwExceptionImpl() async {
    throw Exception('unexpected');
  }
}
