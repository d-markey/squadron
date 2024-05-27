import 'dart:async';

import '_impl/xplat/_typedefs.dart'
    if (dart.library.io) '_impl/native/_typedefs.dart'
    if (dart.library.html) '_impl/browser/_typedefs.dart'
    if (dart.library.js_interop) '_impl/wasm/_typedefs.dart' as impl;

typedef EntryPoint = impl.EntryPoint;
typedef PlatformChannel = impl.PlatformChannel;
typedef PlatformThread = impl.PlatformThread;

typedef PlatformThreadHook = FutureOr<void> Function(PlatformThread);

typedef DbgTrace = void Function(dynamic);

// ignore: constant_identifier_names
const int platform_id = impl.platform_id;

void _noop(dynamic message) {}

// ignore: dead_code
DbgTrace dbgTrace = (true ? impl.trace : _noop);
