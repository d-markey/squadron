import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../xplat/hex.dart';

@JS()
external web.EventTarget get self;

final threadId = () {
  final global = self.dartify();
  return global.hashCode.hex;
}();

typedef EntryPoint = Uri;
typedef PlatformThread = web.Worker;
typedef PlatformChannel = web.MessagePort;

typedef PlatformThreadHook = FutureOr<void> Function(PlatformThread);
