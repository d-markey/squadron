import 'cancellation_token.dart';
import 'channel.dart';
import 'squadron.dart';
import 'squadron_error.dart';
import 'worker.dart';

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
  WorkerRequest(dynamic channelInfo, int command, List args,
      CancellationToken? token, bool inspectResponse)
      : this._(channelInfo, command, null, args, null, token, null,
            inspectResponse);

  /// Creates a new start request.
  WorkerRequest.start(dynamic channelInfo, String id, List args)
      : this._(channelInfo, _connectCommand, id, args, Squadron.logLevel, null,
            null, true);

  /// Creates a new cancellation request.
  WorkerRequest.cancelStream(int streamId)
      : this._(null, _cancelStreamCommand, null, _noArgs, null, null, streamId,
            false);

  /// Creates a new cancellation request.
  WorkerRequest.cancel(CancellationToken token)
      : this._(null, _cancelCommand, null, _noArgs, null, token, null, false);

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
  static const _$timestamp = 'i';

  /// Creates a new [WorkerRequest] from a message received by the worker.
  static WorkerRequest? deserialize(Map? message) {
    if (message == null) return null;
    final req = WorkerRequest._(
      message[_$client],
      message[_$command],
      message[_$id],
      message[_$args] ?? const [],
      message[_$logLevel],
      CancellationToken.deserialize(message[_$token]),
      message[_$streamId],
      message[_$inspectResponse] ?? true,
    );
    final ts = message[_$timestamp];
    if (ts != null) {
      req._travelTime = DateTime.now().microsecondsSinceEpoch - (ts as int);
    }
    return req;
  }

  /// [WorkerRequest] serialization.
  Map<String, dynamic> serialize() {
    if (terminate) {
      return {
        _$command: _terminateCommand,
        if (Squadron.debugMode)
          _$timestamp: DateTime.now().microsecondsSinceEpoch,
      };
    } else if (connect) {
      return {
        _$client: client?.serialize(),
        _$command: _connectCommand,
        _$logLevel: logLevel,
        _$id: id,
        if (args.isNotEmpty) _$args: args,
        if (!inspectResponse) _$inspectResponse: inspectResponse,
        if (Squadron.debugMode)
          _$timestamp: DateTime.now().microsecondsSinceEpoch,
      };
    } else {
      return {
        if (client != null) _$client: client?.serialize(),
        _$command: command,
        if (args.isNotEmpty) _$args: args,
        if (_cancelToken != null) _$token: _cancelToken!.serialize(),
        if (streamId != null) _$streamId: streamId,
        if (!inspectResponse) _$inspectResponse: inspectResponse,
        if (Squadron.debugMode)
          _$timestamp: DateTime.now().microsecondsSinceEpoch,
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

  /// The ID of the worker that initiated the command (only used for connection commands).
  final String? id;

  /// The command's arguments, if any.
  final List args;

  /// The current Squadron log level.
  /// This is set automatically and only used for connection commands.
  final int? logLevel;

  /// Flag indicating whether the Channel should inspect the payload to identify non-base type objects. In
  /// Web workers, ownership of these objects must be transfered across threads.
  final bool inspectResponse;

  /// When [Squadron.debugMode] is `true`, [travelTime] is set by the receiving end and measures the time
  /// (in microseconds) it took between the moment the message was serialized and the moment it was
  /// deserialized.
  int? get travelTime => _travelTime;
  int? _travelTime;

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
