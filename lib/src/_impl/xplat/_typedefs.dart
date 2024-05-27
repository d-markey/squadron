import 'dart:async';

typedef EntryPoint = dynamic;
typedef PlatformThread = dynamic;
typedef PlatformChannel = dynamic;

typedef PlatformThreadHook = FutureOr<void> Function(PlatformThread);

// ignore: constant_identifier_names
const int platform_id = 0;

void trace(dynamic message) => print(message?.toString() ?? '(null)');
