import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

typedef EntryPoint = String;
typedef PlatformThread = web.Worker;
typedef PlatformChannel = web.MessagePort;

typedef PlatformThreadHook = FutureOr<void> Function(PlatformThread);

// ignore: constant_identifier_names
const int platform_id = 3;

void trace(dynamic message) =>
    web.console.log((message?.toString() ?? '(null)').jsify());
