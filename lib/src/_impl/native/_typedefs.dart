import 'dart:async';
import 'dart:isolate';

import '../../worker/worker_request.dart';
import '../xplat/hex.dart';

final threadId = Isolate.current.hashCode.hex;

typedef EntryPoint = FutureOr<void> Function(WorkerRequest);
typedef PlatformThread = Isolate;
typedef PlatformChannel = SendPort;

typedef PlatformThreadHook = FutureOr<void> Function(PlatformThread);
