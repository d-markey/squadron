import '_impl/xplat/_channel.dart'
    if (dart.library.io) '_impl/native/_channel.dart'
    if (dart.library.js) '_impl/browser/_channel.dart'
    if (dart.library.html) '_impl/browser/_channel.dart' as impl;

typedef EntryPoint = impl.EntryPoint;
typedef PlatformWorker = impl.PlatformWorker;
typedef PlatformWorkerHook = impl.PlatformWorkerHook;
