import 'echo_worker_js.dart'
    if (dart.library.js_interop) 'echo_worker_wasm.dart' as impl;

// this is a regular Web worker

void main() => impl.main();
