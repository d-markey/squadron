import 'channel.dart' show Channel, WorkerChannel;
import 'worker_request.dart';

/// Starts a worker using the [entryPoint] and sends a start [WorkerRequest] with [startArguments].
/// The future must not complete before the worker is ready to serve requests.
Future<Channel> openChannel(dynamic entryPoint, List startArguments) =>
    throw UnsupportedError(
        'Channel.open() )is not supported on this platform.');

/// Deserializes a [Channel] from an opaque [channelInfo].
Channel? deserializeChannel(dynamic channelInfo) => throw UnsupportedError(
    'Channel.deserialize() is not supported on this platform.');

/// Deserializes a [WorkerChannel] from an opaque [channelInfo].
WorkerChannel? deserializeWorkerChannel(dynamic channelInfo) =>
    throw UnsupportedError(
        'WorkerChannel.deserialize() is not supported on this platform.');
