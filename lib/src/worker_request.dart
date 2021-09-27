import 'dart:isolate';

import 'worker_exception.dart';
import 'worker_response.dart';

/// Class used to communicate from the worker to its child [Isolate].
/// Typically a [WorkerRequest] consists of a command ID and a list of arguments.
/// The [command] ID is used by the [Isolate]'s main program to dispatch the request to the method responsible for handling it.
/// The request is effectively sent to the [Isolate] by calling the [send] or [stream] method.
/// These methods will serialize the [WorkerRequest] as a simple list containing 3 items:
/// * [0]: the [sendPort] of the [ReceivePort] that was created to communicate with the [Isolate]
/// * [1]: the [command] ID
/// * [3]: the command's arguments [args]
/// The command's arguments is passed as a list and should only contain objects that can be sent via the [Isolate]'s [SendPort] (typically, primitive types and lists or maps). However according to Dart's documentation of [SendPort.send], passing object instances should also be possible.
/// The [Isolate]'s main program must accept a single [List] argument which may be deserialized using the [WorkerRequest.fromMessage] constructor.
class WorkerRequest {
  /// Creates a new request with the specified [command] ID and optional arguments.
  WorkerRequest(this.command, [this.args = const []])
      : assert(command != null),
        sendPort = null;

  WorkerRequest._(this.args)
      : command = null,
        sendPort = null;

  /// Creates a new request from the list received by the [Isolate]'s main program.
  WorkerRequest.fromMessage(List message)
      : assert(message[0] is SendPort),
        sendPort = message[0],
        command = message[1],
        args = message[2];

  /// Creates arguments to be passed to the [Isolate] upon startup. Used internally.
  static List startArguments(ReceivePort receiver, List args) =>
      WorkerRequest._(args)._serialize(receiver);

  /// Creates arguments to be passed to the [Isolate] to shut it down. Used internally.
  static List stopArguments(ReceivePort receiver) =>
      WorkerRequest._([])._serialize(receiver);

  /// The [command]'s ID
  final int? command;

  /// The command's arguments, if any
  final List args;

  /// The [SendPort] of the ReceivePort used to called the [Isolate]. Results must be sent back via this [SendPort].
  final SendPort? sendPort;

  List _serialize(ReceivePort receiver) => [receiver.sendPort, command, args];

  /// This method should be used by the [Isolate]'s main program upon startup to connect it with its parent worker.
  void connect(ReceivePort port) {
    assert(sendPort != null);
    sendPort!.send(port.sendPort);
  }

  /// Send a value from the [Isolate] to its parent worker.
  void reply([dynamic result]) {
    assert(sendPort != null);
    sendPort!.send(WorkerResponse(result).serialize());
  }

  /// Send an 'end-of-stream' message from the [Isolate] to its parent worker.
  void endOfStream() {
    assert(sendPort != null);
    sendPort!.send(WorkerResponse.endOfStream().serialize());
  }

  /// Send a response representing an error from the [Isolate] to its parent worker.
  void exception(dynamic error, StackTrace stackTrace) {
    assert(sendPort != null);
    if (error is WorkerException) {
      sendPort!.send(WorkerResponse.withError(error.message, error.stackTrace)
          .serialize());
    } else {
      sendPort!.send(WorkerResponse.withError(
              error?.toString() ?? 'Unknown exception', stackTrace.toString())
          .serialize());
    }
  }

  /// Send the request from the worker to the child [Isolate], and wait for a single result
  Future<T> send<T>(SendPort remote) async {
    // send the request and wait for the response
    final receiver = ReceivePort();
    remote.send(_serialize(receiver));
    final resp = await receiver.first;

    // return to caller
    return WorkerResponse.fromMessage(resp).result as T;
  }

  /// Send the request from the worker to the child [Isolate], and wait for a stream of results
  Stream<T> stream<T>(SendPort remote) async* {
    // send the request and wait for the response
    final receiver = ReceivePort();
    remote.send(_serialize(receiver));
    await for (var resp in receiver) {
      var res = WorkerResponse.fromMessage(resp);
      if (res.endOfStream) {
        receiver.close();
        break;
      }
      yield res.result as T;
    }
  }
}
