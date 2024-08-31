import 'dart:async';

import '_impl/xplat/_typedefs.dart'
    if (dart.library.io) '_impl/native/_typedefs.dart'
    if (dart.library.html) '_impl/web/_typedefs.dart'
    if (dart.library.js_interop) '_impl/web/_typedefs.dart' as impl;

final threadId = impl.threadId;

typedef EntryPoint = impl.EntryPoint;
typedef PlatformChannel = impl.PlatformChannel;
typedef PlatformThread = impl.PlatformThread;

typedef PlatformThreadHook = FutureOr<void> Function(PlatformThread);

extension HexExt on int {
  String get hex => '0x${toRadixString(16).padLeft(8, '0')}';
}
