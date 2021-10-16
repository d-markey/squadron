import 'dart:async';
import 'package:squadron/squadron.dart';

import 'channel.dart' show Channel;

/// starts a worker using the [entryPoint] and sends a start [WorkerRequest] with [startArguments]
/// the future must not complete before the worker is ready to serve requests
Future<Channel> Function(dynamic entryPoint, List startArguments)
    get openChannel {
  throw UnsupportedError('Channel.open() )is not supported on this platform.');
}

/// deserializes a [Channel] from an opaque [channelInfo]
Channel? Function(dynamic channelInfo) get deserializeChannel {
  throw UnsupportedError(
      'Channel.deserialize() is not supported on this platform.');
}
