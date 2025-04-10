import 'package:meta/meta.dart';

import '../_impl/xplat/_internal_logger.dart';
import '../_impl/xplat/_time_stamp.dart';
import '../exceptions/squadron_error.dart';
import '../tokens/_squadron_cancelation_token.dart';
import '../typedefs.dart';
import 'worker.dart';
import 'worker_channel.dart';
import 'worker_message.dart';

/// [WorkerRequest]s are used to communicate from a client to a [Worker].
/// Typically a [WorkerRequest] consists of a command ID and a list of
/// arguments. The [command] ID is used by the [Worker] to dispatch the
/// [WorkerRequest] to the method responsible for handling it.
/// The command's arguments are passed as a list and should only contain
/// primitive values or objects that can be transfered across workers. For
/// applications running on a VM platform, Dart objects should be safe
/// according to Dart's documentation of [SendPort.send]. [WorkerRequestImpl]
/// also implements specific requests used for worker startup, stream/token
/// cancelation, worker termination...
extension type WorkerRequest._(List data) implements WorkerMessage {
  /// Creates a new request with the specified [command] ID and optional arguments.
  static WorkerRequest userCommand(PlatformChannel channelInfo, int command,
          List args, SquadronCancelationToken? token, bool inspectResponse) =>
      WorkerRequest._([
        microsecTimeStamp(), // 0 - travel time
        channelInfo, // 1 - channel
        command, // 2 - command
        args, // 3 - args
        token, // 4 - cancelation token
        null, // 5 - stream id
        inspectResponse, // 6 - inspect response
      ]);

  /// Creates a new start request.
  static WorkerRequest start(PlatformChannel channelInfo, List args) =>
      WorkerRequest._([
        microsecTimeStamp(), // 0 - travel time
        channelInfo, // 1 - channel
        _connectCommand, // 2 - command
        args, // 3 - args
        null, // 4 - cancelation token
        null, // 5 - stream id
        true, // 6 - inspect response
      ]);

  /// Creates a new stream cancelation request.
  static WorkerRequest cancelStream(int streamId) => WorkerRequest._([
        microsecTimeStamp(), // 0 - travel time
        null, // 1 - channel
        _cancelStreamCommand, // 2 - command
        null, // 3 - args
        null, // 4 - cancelation token
        streamId, // 5 - stream id
        null, // 6 - inspect response
      ]);

  /// Creates a new cancelation request.
  static WorkerRequest cancel(SquadronCancelationToken token) =>
      WorkerRequest._([
        microsecTimeStamp(), // 0 - travel time
        null, // 1 - channel
        _cancelTokenCommand, // 2 - command
        null, // 3 - args
        token, // 4 - cancelation token
        null, // 5 - stream id
        null, // 6 - inspect response
      ]);

  /// Creates a new termination request.
  static WorkerRequest stop() => WorkerRequest._([
        microsecTimeStamp(), // 0 - travel time
        null, // 1 - channel
        _terminateCommand, // 2 - command
        null, // 3 - args
        null, // 4 - cancelation token
        null, // 5 - stream id
        null, // 6 - inspect response
      ]);

  /// The client's [WorkerChannel]. Only valid on the receiving end.
  WorkerChannel? get channel => data[_$channel];

  /// The channel method to be used for sending data back.
  void Function(dynamic)? get reply =>
      inspectResponse ? channel?.inspectAndReply : channel?.reply;

  /// The client's channel info.
  PlatformChannel? get channelInfo => data[_$channel];

  /// Cancelation token.
  SquadronCancelationToken? get cancelToken => data[_$token];

  /// Stream id.
  int? get streamId => data[_$streamId];

  /// The [command]'s ID.
  int get command => data[_$command];

  /// The command's arguments, if any.
  List get args => data[_$args];

  /// Flag indicating whether the Channel should inspect the payload to identify non-base type objects. In
  /// Web Workers, ownership of these objects must be transfered across threads.
  bool get inspectResponse => data[_$inspectResponse];

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

// 0 is reserved for travel time
const _$channel = 1;
const _$command = 2;
const _$args = 3;
const _$token = 4;
const _$streamId = 5;
const _$inspectResponse = 6;

@internal
extension WorkerRequestExt on WorkerRequest {
  /// In-place deserialization of a [WorkerRequest] received by the worker.
  void unwrapInPlace(InternalLogger? logger) {
    unwrapTravelTime();
    data[_$command] = (data[_$command] as num).toInt();
    data[_$streamId] = (data[_$streamId] as num?)?.toInt();
    data[_$channel] = WorkerChannel.deserialize(data[_$channel], logger);
    data[_$token] = SquadronCancelationToken.deserialize(data[_$token]);
    data[_$inspectResponse] ??= false;
    data[_$args] ??= const [];
  }

  /// In-place serialization of a [WorkerRequest].
  List wrapInPlace() {
    final token = data[_$token];
    if (token is SquadronCancelationToken) {
      data[_$token] = token.serialize();
    }
    return data;
  }

  static WorkerRequest from(List data) {
    if (data.length != 7) {
      throw SquadronErrorImpl.create('Invalid worker request');
    }
    return WorkerRequest._(data);
  }
}

@internal
extension CancelationTokenExt on WorkerRequest {
  void overrideCancelToken(SquadronCancelationToken token) {
    if (cancelToken == null || cancelToken!.id != token.id) {
      throw SquadronErrorImpl.create('Cancelation token mismatch');
    }
    data[_$token] = token;
  }
}
