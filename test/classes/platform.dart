import 'package:squadron/squadron.dart';

import 'platform_stub.dart'
    if (dart.library.js_interop) 'platform_wasm.dart'
    if (dart.library.js) 'platform_browser.dart'
    if (dart.library.html) 'platform_browser.dart'
    if (dart.library.io) 'platform_native.dart' as impl;

dynamic getUnsendable() => impl.getUnsendable();

WorkerChannel? getWorkerChannel(Logger? logger) =>
    impl.getWorkerChannel(logger);

String get threadId => impl.threadId;
