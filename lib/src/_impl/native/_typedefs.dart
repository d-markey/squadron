import 'dart:async';
import 'dart:isolate';

typedef EntryPoint = FutureOr<void> Function(List);
typedef PlatformThread = Isolate;
typedef PlatformChannel = SendPort;

typedef PlatformThreadHook = FutureOr<void> Function(PlatformThread);

// ignore: constant_identifier_names
const int platform_id = 1;

void trace(dynamic message) => print(message?.toString() ?? '(null)');
