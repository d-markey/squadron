import 'dart:async';

import 'package:web/web.dart' as web;

typedef WebPlatformThread = web.Worker;
typedef WebPlatformChannel = web.MessagePort;
typedef WebPlatformThreadHook = FutureOr<void> Function(WebPlatformThread);

typedef PlatformThread = WebPlatformThread;
typedef PlatformChannel = WebPlatformChannel;
typedef PlatformThreadHook = WebPlatformThreadHook;
