import 'dart:async';

import 'package:web/web.dart' as web;

typedef EntryPoint = String;
typedef PlatformThread = web.Worker;
typedef PlatformChannel = web.MessagePort;

typedef PlatformThreadHook = FutureOr<void> Function(PlatformThread);
