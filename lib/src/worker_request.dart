import 'cancellation_token.dart';
import 'channel.dart';
import 'squadron.dart';
import 'squadron_error.dart';
import 'worker.dart';
import 'xplat/_identity.dart';

/// Class used to communicate from a [Channel] to the [Worker]. Typically a [WorkerRequest] consists of a command ID
/// and a list of arguments. The [command] ID is used by the [Worker] to dispatch the [WorkerRequest] to the method
/// responsible for handling it. The [WorkerRequest] is effectively sent to the [Worker] by calling the
/// [WorkerRequest.send] or [WorkerRequest.stream] method. These methods will serialize the [WorkerRequest] as a
/// [Map] to be transfered from the client to the worker and contains:
/// * the serialized [Channel] to communicate with the [Worker]
/// * the [command] ID
/// * the command's arguments [args]
/// The command's arguments are passed as a list and should only contain primitive values or objects that can be
/// transfered across workers. For applications running on a VM platform, Dart objects should be safe according to
/// Dart's documentation of [SendPort.send]. The worker is responsible for deserializing the messages it receives
/// using the [WorkerRequest.deserialize] constructor. [WorkerRequest] also implements specific requests used
/// for worker startup, token cancellation, and worker termination.
class WorkerRequest {
  static const _noArgs = [];

  WorkerRequest._(dynamic channelInfo, this.command, this.id, this.args,
      this.logLevel, this._cancelToken, this.streamId, this.inspectResponse)
      : client = WorkerChannel.deserialize(channelInfo);

  /// Creates a new request with the specified [command] ID and optional arguments.
  WorkerRequest(dynamic channelInfo, int command,
      [List args = _noArgs,
      CancellationToken? cancelToken,
      bool inspectResponse = true])
      : this._(channelInfo, command, null, args, null, cancelToken, null,
            inspectResponse);

  /// Creates a new start request.
  WorkerRequest.start(dynamic channelInfo,
      [List args = _noArgs, bool inspectResponse = true])
      : this._(channelInfo, _connectCommand, Identity.nextId(), args,
            Squadron.logLevel, null, null, inspectResponse);

  /// Creates a new cancellation request.
  WorkerRequest.cancelStream(int streamId)
      : this._(null, _cancelStreamCommand, null, _noArgs, null, null, streamId,
            false);

  /// Creates a new cancellation request.
  WorkerRequest.cancel(CancellationToken cancelToken)
      : this._(null, _cancelCommand, null, _noArgs, null, cancelToken, null,
            false);

  /// Creates a new termination request.
  WorkerRequest.stop()
      : this._(null, _terminateCommand, null, _noArgs, null, null, null, false);

  static const _$client = 'a';
  static const _$command = 'b';
  static const _$args = 'c';
  static const _$token = 'd';
  static const _$streamId = 'e';
  static const _$id = 'f';
  static const _$logLevel = 'g';
  static const _$inspectResponse = 'h';

  /// Creates a new [WorkerRequest] from a message received by the worker.
  static WorkerRequest? deserialize(Map? message) => (message == null)
      ? null
      : WorkerRequest._(
          message[_$client],
          message[_$command],
          message[_$id],
          message[_$args] ?? const [],
          message[_$logLevel],
          CancellationToken.deserialize(message[_$token]),
          message[_$streamId],
          message[_$inspectResponse] ?? true,
        );

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
        if (!inspectResponse) _$inspectResponse: inspectResponse
      };
    } else {
      return {
        if (client != null) _$client: client?.serialize(),
        _$command: command,
        if (args.isNotEmpty) _$args: args,
        if (_cancelToken != null) _$token: _cancelToken!.serialize(),
        if (streamId != null) _$streamId: streamId,
        if (!inspectResponse) _$inspectResponse: inspectResponse
      };
    }
  }

  /// The client's [WorkerChannel].
  final WorkerChannel? client;

  /// Cancellation token.
  CancellationToken? get cancelToken => _cancelToken;
  CancellationToken? _cancelToken;

  /// Stream id.
  final int? streamId;

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

  /// Flag indicating whether the Channel should inspect the payload to identify non-base type objects. In
  /// Web workers, ownership of these objects must be transfered across threads.
  final bool inspectResponse;

  /// flag for start requests.
  bool get connect => command == _connectCommand;

  /// flag for stream cancellation requests.
  bool get cancelStream => command == _cancelStreamCommand;

  /// flag for cancellation requests.
  bool get cancel => command == _cancelCommand;

  /// flag for termination requests.
  bool get terminate => command == _terminateCommand;

  static const int _connectCommand = -1;
  static const int _cancelStreamCommand = -2;
  static const int _cancelCommand = -3;
  static const int _terminateCommand = -4;
}

// for internal use
extension WorkerRequestExt on WorkerRequest {
  void overrideCancelToken(CancellationToken token) {
    if (_cancelToken == null || _cancelToken!.id != token.id) {
      throw newSquadronError('cancellation token mismatch');
    }
    _cancelToken = token;
  }
}
