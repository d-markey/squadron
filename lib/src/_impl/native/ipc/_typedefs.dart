import 'dart:async';
import 'dart:io';

typedef IpcPlatformThread = Process;
typedef IpcPlatformChannel = dynamic;
typedef IpcPlatformThreadHook = FutureOr<void> Function(IpcPlatformThread);
