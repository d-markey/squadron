import 'dart:async';
import 'dart:isolate';

typedef InProcPlatformThread = Isolate;
typedef InProcPlatformChannel = SendPort;
typedef InProcPlatformThreadHook = FutureOr<void> Function(
    InProcPlatformThread);
