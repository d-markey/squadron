import 'package:meta/meta.dart';

import '../_impl/xplat/_helpers.dart';
import '../_impl/xplat/_internal_logger.dart';
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
extension type WorkerRequest(List data) implements WorkerMessage {
  /// Creates a new request with the specified [command] ID and optional arguments.
  static WorkerRequest userCommand(PlatformChannel channelInfo, int command,
          List args, SquadronCancelationToken? token, bool inspectResponse) =>
      WorkerRequest([
        microsecTimeStamp(), // 0 - travel time
        channelInfo, // 1 - client
        command, // 2 - command
        args, // 3 - args
        token, // 4 - cancelation token
        null, // 5 - stream id
        inspectResponse, // 6 - inspect response
      ]);

  /// Creates a new start request.
  static WorkerRequest start(PlatformChannel channelInfo, List args) =>
      WorkerRequest([
        microsecTimeStamp(), // 0 - travel time
        channelInfo, // 1 - client
        _connectCommand, // 2 - command
        args, // 3 - args
        null, // 4 - cancelation token
        null, // 5 - stream id
        true, // 6 - inspect response
      ]);

  /// Creates a new stream cancelation request.
  static WorkerRequest cancelStream(int streamId) => WorkerRequest([
        microsecTimeStamp(), // 0 - travel time
        null, // 1 - client
        _cancelStreamCommand, // 2 - command
        null, // 3 - args
        null, // 4 - cancelation token
        streamId, // 5 - stream id
        null, // 6 - inspect response
      ]);

  /// Creates a new cancelation request.
  static WorkerRequest cancel(SquadronCancelationToken token) => WorkerRequest([
        microsecTimeStamp(), // 0 - travel time
        null, // 1 - client
        _cancelTokenCommand, // 2 - command
        null, // 3 - args
        token, // 4 - cancelation token
        null, // 5 - stream id
        null, // 6 - inspect response
      ]);

  /// Creates a new termination request.
  static WorkerRequest stop() => WorkerRequest([
        microsecTimeStamp(), // 0 - travel time
        null, // 1 - client
        _terminateCommand, // 2 - command
        null, // 3 - args
        null, // 4 - cancelation token
        null, // 5 - stream id
        null, // 6 - inspect response
      ]);

  /// The client's [WorkerChannel]. Only valid on the receiving end.
  WorkerChannel? get client => data[_$client];

  /// The channel method to be used for sending data back.
  void Function(dynamic)? get reply =>
      inspectResponse ? client?.inspectAndReply : client?.reply;

  /// The client's channel info.
  PlatformChannel? get channelInfo => data[_$client];

  /// Cancelation token.
  SquadronCancelationToken? get cancelToken => data[_$token];

  /// Stream id.
  int? get streamId => data[_$streamId];

  /// The [command]'s ID.
  int get command => data[_$command];

  /// The command's arguments, if any.
  List get args => data[_$args];

  /// Flag indicating whether the Channel should inspect the payload to identify non-base type objects. In
  /// Web workers, ownership of these objects must be transfered across threads.
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
const _$client = 1;
const _$command = 2;
const _$args = 3;
const _$token = 4;
const _$streamId = 5;
const _$inspectResponse = 6;

@internal
extension WorkerRequestExt on WorkerRequest {
  /// In-place deserialization of a [WorkerRequest] received by the worker.
  void unwrapInPlace(InternalLogger? logger) {
    dbgTrace('UNWRAP REQUEST $this...');
    dbgTrace('   unwrap command ${data[_$command]}...');
    data[_$command] = (data[_$command] as num?)?.toInt();
    dbgTrace('   unwrap streamId ${data[_$streamId]}...');
    data[_$streamId] = (data[_$streamId] as num?)?.toInt();
    dbgTrace('   unwrap client ${data[_$client]}...');
    data[_$client] = WorkerChannel.deserialize(data[_$client], logger);
    dbgTrace('   unwrap token ${data[_$token]}...');
    data[_$token] = SquadronCancelationToken.deserialize(data[_$token]);
    dbgTrace('   unwrap inspectResponse ${data[_$inspectResponse]}...');
    data[_$inspectResponse] ??= false;
    dbgTrace('   unwrap args ${data[_$args]}...');
    data[_$args] ??= const [];
    unwrapTravelTime();
    dbgTrace('   result = $this');
  }

  /// In-place serialization of a [WorkerRequest].
  void wrapInPlace() {
    dbgTrace('WRAP REQUEST $this...');
    dbgTrace('   wrap token ${data[_$token]}...');
    final token = data[_$token];
    if (token is SquadronCancelationToken) {
      data[_$token] = token.serialize();
    }
    dbgTrace('   result = $this');
  }
}

@internal
extension CancelationTokenExt on WorkerRequest {
  void overrideCancelToken(SquadronCancelationToken token) {
    if (cancelToken == null || cancelToken!.id != token.id) {
      throw SquadronErrorExt.create(
          'cancelation token mismatch', StackTrace.current);
    }
    data[_$token] = token;
  }
}
