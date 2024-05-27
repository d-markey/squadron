import 'dart:async';
import 'dart:html' as web;

typedef EntryPoint = String;
typedef PlatformThread = web.Worker;
typedef PlatformChannel = web.MessagePort;

typedef PlatformThreadHook = FutureOr<void> Function(PlatformThread);

// ignore: constant_identifier_names
const int platform_id = 2;

void trace(dynamic message) =>
    web.window.console.log(message?.toString() ?? '(null)');
