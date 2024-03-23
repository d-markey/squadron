import 'dart:async';

import '_impl/xplat/_typedefs.dart'
    if (dart.library.io) '_impl/native/_typedefs.dart'
    if (dart.library.js) '_impl/browser/_typedefs.dart'
    if (dart.library.html) '_impl/browser/_typedefs.dart' as impl;

typedef EntryPoint = impl.EntryPoint;
typedef PlatformChannel = impl.PlatformChannel;
typedef PlatformThread = impl.PlatformThread;

typedef PlatformThreadHook = FutureOr<void> Function(PlatformThread);
