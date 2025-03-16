import 'dart:async';
import 'dart:math';

import 'package:meta/meta.dart';
import 'package:web/web.dart' as web;

import '../../utils.dart';
import '../../worker/worker_request.dart';

// threadIDs may not be unique on Web...
final threadId = Random.secure().nextInt(0x100000000).hex;

typedef EntryPoint = Uri;
typedef PlatformThread = web.Worker;
typedef PlatformChannel = web.MessagePort;
typedef PlatformThreadHook = FutureOr<void> Function(PlatformThread);

@internal
extension WorkerRequestExt on WorkerRequest {
  PlatformChannel? get webChannelInfo => (channelInfo as PlatformChannel?);
}
