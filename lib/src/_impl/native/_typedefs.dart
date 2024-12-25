import 'dart:async';
import 'dart:isolate';

import '../../utils.dart';
import '../../worker/worker_request.dart';

final threadId = Isolate.current.hashCode.hex;

typedef EntryPoint = FutureOr<void> Function(WorkerRequest);
typedef PlatformThread = Isolate;
typedef PlatformChannel = SendPort;

typedef PlatformThreadHook = FutureOr<void> Function(PlatformThread);
