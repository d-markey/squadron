import 'package:logger/logger.dart';
import 'package:meta/meta.dart';

import '../_impl/xplat/_helpers.dart';
import '../channel.dart';
import '../exceptions/squadron_error.dart';
import '../tokens/_squadron_cancelation_token.dart';
import '../typedefs.dart';
import 'worker.dart';
import 'worker_channel.dart';
import 'worker_message.dart';

/// Make [WorkerRequest] a [WorkerMessage] to minimize serialization overhead.
typedef WorkerRequest = WorkerMessage;

/// Extension methods operating on a `List` as a [WorkerRequest].
/// [WorkerRequest]s are used to communicate from a [Channel] to a [Worker].
/// Typically a [WorkerRequest] consists of a command ID and a list of
/// arguments. The [command] ID is used by the [Worker] to dispatch the
/// [WorkerRequest] to the method responsible for handling it.
/// The command's arguments are passed as a list and should only contain
/// primitive values or objects that can be transfered across workers. For
/// applications running on a VM platform, Dart objects should be safe
/// according to Dart's documentation of [SendPort.send]. [WorkerRequestImpl]
/// also implements specific requests used for worker startup, stream/token
/// cancelation, worker termination...
extension WorkerRequestImpl on WorkerRequest {
  // 0 is reserved for travel time
  static const _$client = 1;
  static const _$command = 2;
  static const _$args = 3;
  static const _$token = 4;
  static const _$streamId = 5;
  static const _$inspectResponse = 6;

  /// Creates a new request with the specified [command] ID and optional arguments.
  static WorkerRequest userCommand(PlatformChannel channelInfo, int command,
          List args, SquadronCancelationToken? token, bool inspectResponse) =>
      [
        microsecTimeStamp(), // 0 - travel time
        channelInfo, // 1 - client
        command, // 2 - command
        args, // 3 - args
        token, // 4 - cancelation token
        null, // 5 - stream id
        inspectResponse, // 6 - inspect response
      ];

  /// Creates a new start request.
  static WorkerRequest start(PlatformChannel channelInfo, List args) => [
        microsecTimeStamp(), // 0 - travel time
        channelInfo, // 1 - client
        _connectCommand, // 2 - command
        args, // 3 - args
        null, // 4 - cancelation token
        null, // 5 - stream id
        true, // 6 - inspect response
      ];

  /// Creates a new stream cancelation request.
  static WorkerRequest cancelStream(int streamId) => [
        microsecTimeStamp(), // 0 - travel time
        null, // 1 - client
        _cancelStreamCommand, // 2 - command
        null, // 3 - args
        null, // 4 - cancelation token
        streamId, // 5 - stream id
        null, // 6 - inspect response
      ];

  /// Creates a new cancelation request.
  static WorkerRequest cancel(SquadronCancelationToken token) => [
        microsecTimeStamp(), // 0 - travel time
        null, // 1 - client
        _cancelTokenCommand, // 2 - command
        null, // 3 - args
        token, // 4 - cancelation token
        null, // 5 - stream id
        null, // 6 - inspect response
      ];

  /// Creates a new termination request.
  static WorkerRequest stop() => [
        microsecTimeStamp(), // 0 - travel time
        null, // 1 - client
        _terminateCommand, // 2 - command
        null, // 3 - args
        null, // 4 - cancelation token
        null, // 5 - stream id
        null, // 6 - inspect response
      ];

  /// The client's [WorkerChannel]. Only valid on the receiving end.
  WorkerChannel? get client => this[_$client];

  /// The channel method to be used for sending data back.
  void Function(dynamic)? get reply =>
      inspectResponse ? client?.inspectAndReply : client?.reply;

  /// The client's channel info.
  PlatformChannel? get channelInfo => this[_$client];

  /// Cancelation token.
  SquadronCancelationToken? get cancelToken => this[_$token];

  /// Stream id.
  int? get streamId => this[_$streamId];

  /// The [command]'s ID.
  int get command => this[_$command];

  /// The command's arguments, if any.
  List get args => this[_$args];

  /// Flag indicating whether the Channel should inspect the payload to identify non-base type objects. In
  /// Web workers, ownership of these objects must be transfered across threads.
  bool get inspectResponse => this[_$inspectResponse];

  /// flag for start requests.
  bool get isConnection => (command == _connectCommand);

  /// flag for stream cancelation requests.
  bool get isStreamCancelation => (command == _cancelStreamCommand);

  /// flag for cancelation requests.
  bool get isTokenCancelation => (command == _cancelTokenCommand);

  /// flag for termination requests.
  bool get isTermination => (command == _terminateCommand);

  static const int _connectCommand = -1;
  static const int _cancelStreamCommand = -2;
  static const int _cancelTokenCommand = -3;
  static const int _terminateCommand = -4;
}

@internal
extension WorkerRequestExt on WorkerRequest {
  static const _$client = WorkerRequestImpl._$client;
  static const _$args = WorkerRequestImpl._$args;
  static const _$token = WorkerRequestImpl._$token;
  static const _$inspectResponse = WorkerRequestImpl._$inspectResponse;

  /// In-place deserialization of a [WorkerRequest] received by the worker.
  void unwrapRequestInPlace(Logger? logger) {
    this[_$client] = WorkerChannel.deserialize(this[_$client], logger);
    this[_$token] = SquadronCancelationToken.deserialize(this[_$token]);
    this[_$inspectResponse] ??= false;
    this[_$args] ??= const [];
    unwrapTravelTime();
  }

  /// In-place serialization of a [WorkerRequest].
  void wrapRequestInPlace() {
    final token = this[_$token];
    if (token is SquadronCancelationToken) {
      this[_$token] = token.serialize();
    }
  }
}

@internal
extension CancelationTokenExt on WorkerRequest {
  void overrideCancelToken(SquadronCancelationToken token) {
    if (cancelToken == null || cancelToken!.id != token.id) {
      throw SquadronErrorExt.create(
          'cancelation token mismatch', StackTrace.current);
    }
    this[WorkerRequestExt._$token] = token;
  }
}
