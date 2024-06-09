import '_platform_stub.dart'
    if (dart.library.io) '../workers/vm/_platform.dart'
    if (dart.library.html) '../workers/js/_platform.dart'
    if (dart.library.js_interop) '../workers/wasm/_platform.dart' as impl;

final getUnsendable = impl.getUnsendable;
final threadId = impl.threadId;
