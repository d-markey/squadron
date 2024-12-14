import 'dart:async';
import 'dart:isolate';

import '../../typedefs.dart' show HexExt;
import '../../worker/worker_request.dart';

final threadId = Isolate.current.hashCode.hex;

typedef EntryPoint = FutureOr<void> Function(WorkerRequest);
typedef PlatformThread = Isolate;
typedef PlatformChannel = SendPort;
