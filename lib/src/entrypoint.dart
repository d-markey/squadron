import 'xplat/_channel.dart'
    if (dart.library.io) 'native/_channel.dart'
    if (dart.library.js) 'browser/_channel.dart'
    if (dart.library.html) 'browser/_channel.dart' as impl;

typedef EntryPoint = impl.EntryPoint;
typedef PlatformWorker = impl.PlatformWorker;
typedef PlatformWorkerHook = impl.PlatformWorkerHook;
