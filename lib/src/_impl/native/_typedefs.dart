import 'dart:async';
import 'dart:isolate';

typedef EntryPoint = FutureOr<void> Function(List);
typedef PlatformThread = Isolate;
typedef PlatformChannel = SendPort;
