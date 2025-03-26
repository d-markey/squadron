import 'dart:async';

typedef EntryPoint = Object;
typedef PlatformThread = Object;
typedef PlatformChannel = Object;

typedef PlatformThreadHook = FutureOr<void> Function(PlatformThread);
