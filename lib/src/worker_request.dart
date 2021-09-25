import 'dart:isolate';

import 'worker_exception.dart';
import 'worker_response.dart';

class WorkerRequest {
  WorkerRequest(this.command, [this.args = const []]) : assert(command != null), sendPort = null;

  WorkerRequest.start([this.args = const []]) : command = null, sendPort = null;

  WorkerRequest.stop() : command = null , args = const [], sendPort = null;

  WorkerRequest.fromMessage(List message) : assert(message[0] is SendPort), sendPort = message[0], command = message[1], args = message[2];

  final int? command;
  final List args;

  final SendPort? sendPort;

  List serialize(ReceivePort receiver) => [receiver.sendPort, command, args];

  void connect(ReceivePort port) {
    assert(sendPort != null);
    sendPort!.send(port.sendPort);
  }

  void reply([dynamic result]) {
    assert(sendPort != null);
    sendPort!.send(WorkerResponse(result).serialize());
  }

  void endOfStream() {
    assert(sendPort != null);
    sendPort!.send(WorkerResponse.endOfStream().serialize());
  }

  void exception(dynamic error, StackTrace? stackTrace) {
    assert(sendPort != null);
    sendPort!.send(WorkerResponse.withError(error?.toString() ?? 'Unknown exception', stackTrace?.toString()).serialize());
  }

  Future<T> send<T>(SendPort remote) async {
    // send the request and wait for the response
    final receiver = ReceivePort();
    remote.send(serialize(receiver));
    final resp = await receiver.first;

    // return to caller
    final res = WorkerResponse.fromMessage(resp);
    if (res.error != null) {
      throw WorkerException(res.error!, stackTrace: res.stackTrace);
    }
    return res.result as T;
  }

  Stream<T> stream<T>(SendPort remote) async* {
    // send the request and wait for the response
    final receiver = ReceivePort();
    remote.send(serialize(receiver));
    await for (var resp in receiver) {
      final res = WorkerResponse.fromMessage(resp);
      if (res.error != null) {
        throw WorkerException(res.error!, stackTrace: res.stackTrace);
      }
      if (res.endOfStream) {
        receiver.close();
        break;
      }
      yield res.result as T;
    }
  }
}
