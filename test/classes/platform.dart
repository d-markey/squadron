import '_platform_stub.dart'
    if (dart.library.io) '_platform_native.dart'
    if (dart.library.html) '_platform_browser.dart'
    if (dart.library.js_interop) '_platform_wasm.dart' as impl;

final getUnsendable = impl.getUnsendable;
final getWorkerChannel = impl.getWorkerChannel;
final threadId = impl.threadId;
