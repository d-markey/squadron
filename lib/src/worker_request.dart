import 'cancellation_token.dart';
import 'channel.dart';
import 'squadron.dart';
import 'worker_exception.dart';

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
  WorkerRequest(dynamic channelInfo, this.command,
      [this.args = const [], this._cancelToken])
      : client = WorkerChannel.deserialize(channelInfo),
        id = null,
        logLevel = null;

  /// Creates a new start request.
  WorkerRequest.start(dynamic channelInfo, String id, [this.args = const []])
      : client = WorkerChannel.deserialize(channelInfo),
        command = _connectCommand,
        _cancelToken = null,
        // ignore: prefer_initializing_formals
        id = id,
        logLevel = Squadron.logLevel;

  /// Creates a new cancel request.
  WorkerRequest.cancel(CancellationToken cancelToken)
      : client = null,
        _cancelToken = cancelToken,
        command = _cancelCommand,
        id = null,
        logLevel = null,
        args = const [];

  /// Creates a new termination request.
  WorkerRequest.stop()
      : client = null,
        _cancelToken = null,
        command = _terminateCommand,
        id = null,
        logLevel = null,
        args = const [];

  static const _$client = 'a';
  static const _$command = 'b';
  static const _$args = 'c';
  static const _$token = 'd';
  static const _$id = 'e';
  static const _$logLevel = 'f';

  /// Creates a new [WorkerRequest] from a message received by the worker.
  WorkerRequest.deserialize(Map? message)
      : client = WorkerChannel.deserialize(message?[_$client]),
        _cancelToken = CancellationToken.deserialize(message?[_$token]),
        command = message?[_$command],
        id = message?[_$id],
        logLevel = message?[_$logLevel],
        args = message?[_$args] ?? const [];

  /// [WorkerRequest] serialization.
  Map<String, dynamic> serialize() {
    if (terminate) {
      return const {_$command: _terminateCommand};
    } else if (connect) {
      return {
        _$client: client?.serialize(),
        _$command: _connectCommand,
        _$id: id,
        _$logLevel: logLevel,
        if (args.isNotEmpty) _$args: args,
      };
    } else {
      return {
        if (client != null) _$client: client?.serialize(),
        _$command: command,
        if (args.isNotEmpty) _$args: args,
        if (_cancelToken != null) _$token: _cancelToken!.serialize(),
      };
    }
  }

  /// The client's [WorkerChannel].
  final WorkerChannel? client;

  /// Cancellation token.
  CancellationToken? get cancelToken => _cancelToken;
  CancellationToken? _cancelToken;

  void overrideCancelToken(CancellationToken value) {
    if (_cancelToken == null || _cancelToken!.id != value.id) {
      throw WorkerException('Cancellation token mismatch');
    }
    _cancelToken = value;
  }

  /// The [command]'s ID.
  final int command;

  /// The command's arguments, if any.
  final List args;

  /// The worker id set by the caller, used for logging/debugging purpose.
  /// This is only used for connection commands.
  final String? id;

  /// The current Squadron log level.
  /// This is set automaticallt and only used for connection commands.
  final int? logLevel;

  /// flag for start requests.
  bool get connect => command == _connectCommand;

  /// flag for cancel requests.
  bool get cancel => command == _cancelCommand;

  /// flag for termination requests.
  bool get terminate => command == _terminateCommand;

  static const int _connectCommand = -1;
  static const int _cancelCommand = -2;
  static const int _terminateCommand = -3;
}
