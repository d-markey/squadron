import 'dart:async';

typedef EntryPoint = dynamic;
typedef PlatformThread = dynamic;
typedef PlatformChannel = dynamic;

typedef PlatformThreadHook = FutureOr<void> Function(PlatformThread);
