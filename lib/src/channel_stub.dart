import 'dart:async';

import 'channel.dart' show Channel;

/// Starts a worker using the [entryPoint] and sends a start [WorkerRequest] with [startArguments].
/// The future must not complete before the worker is ready to serve requests.
Future<Channel> Function(dynamic entryPoint, List startArguments)
    get openChannel {
  throw UnsupportedError('Channel.open() )is not supported on this platform.');
}

/// Deserializes a [Channel] from an opaque [channelInfo].
Channel? Function(dynamic channelInfo) get deserializeChannel {
  throw UnsupportedError(
      'Channel.deserialize() is not supported on this platform.');
}
