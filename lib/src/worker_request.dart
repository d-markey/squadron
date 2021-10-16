import 'channel.dart';

/// Class used to communicate from a [Channel] to the [Worker].
/// Typically a [WorkerRequest] consists of a command ID and a list of arguments.
/// The [command] ID is used by the [Worker] to dispatch the [WorkerRequest] to the method responsible for handling it.
/// The [WorkerRequest] is effectively sent to the [Worker] by calling the [WorkerRequest.send] or [WorkerRequest.stream] method.
/// These methods will serialize the [WorkerRequest] as a [Map] to be transfered from the client to the worker and contains:
/// * the serialized [Channel] to communicate with the [Worker]
/// * the [command] ID
/// * the command's arguments [args]
/// The command's arguments are passed as a list and should only contain primitive values or objects that can be transfered across workers.
/// For applications running on a VM platform, Dart objects should be safe according to Dart's documentation of [SendPort.send].
/// The worker is responsible for deserializing the messages it receives using the [WorkerRequest.deserialize] constructor.
/// [WorkerRequest] also implements two specific requests used for worker startup and termination.
class WorkerRequest {
  /// Creates a new request with the specified [command] ID and optional arguments.
  WorkerRequest(dynamic channelInfo, this.command, [this.args = const []])
      : client = Channel.deserialize(channelInfo),
        connect = false,
        terminate = false;

  /// Creates a new start request.
  WorkerRequest.start(dynamic channelInfo, [this.args = const []])
      : client = Channel.deserialize(channelInfo),
        command = null,
        connect = true,
        terminate = false;

  /// Creates a new termination request.
  WorkerRequest.terminate()
      : client = null,
        command = null,
        args = const [],
        connect = false,
        terminate = true;

  /// Map keys for serialization
  static const _$client = 'a';
  static const _$command = 'b';
  static const _$args = 'c';
  static const _$connect = 'd';
  static const _$terminate = 'e';

  /// Creates a new [WorkerRequest] from a message received by the worker.
  WorkerRequest.deserialize(Map message)
      : client = Channel.deserialize(message[_$client]),
        command = message[_$command],
        args = message[_$args] ?? const [],
        connect = message[_$connect] ?? false,
        terminate = message[_$terminate] ?? false;

  /// The client
  final Channel? client;

  /// The [command]'s ID
  final int? command;

  /// The command's arguments, if any
  final List args;

  /// flag for start requests
  final bool connect;

  /// flag for termination requests
  final bool terminate;

  @override
  String toString() =>
      'client = $client, command = $command, args = $args, connect = $connect, terminate = $terminate';

  /// [WorkerRequest] serialization
  Map<String, dynamic> serialize() {
    if (terminate) {
      return {_$terminate: true};
    } else if (connect) {
      return {_$client: client?.serialize(), _$args: args, _$connect: true};
    } else {
      return {_$client: client?.serialize(), _$command: command, _$args: args};
    }
  }
}
