import 'echo_worker.js.dart'
    if (dart.library.js_interop) 'echo_worker.wasm.dart' as impl;

// this is a regular Web worker

void main() {
  impl.main();
}
