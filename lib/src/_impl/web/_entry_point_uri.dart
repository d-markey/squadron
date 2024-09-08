import 'dart:js_interop';

import 'package:using/using.dart';
import 'package:web/web.dart' as web;

import '../../exceptions/squadron_error.dart';

class EntryPointUri with Releasable {
  EntryPointUri._(this.uri, {required bool revoke}) : _revoke = revoke;

  final String uri;
  final bool _revoke;

  @override
  void release() {
    if (_revoke) {
      web.URL.revokeObjectURL(uri);
    }
    super.release();
  }

  factory EntryPointUri.from(Uri workerEntrypoint) {
    final fileName =
        workerEntrypoint.pathSegments.lastOrNull?.toString().toLowerCase() ??
            '';

    if (fileName.endsWith('.js') || fileName.endsWith('.mjs')) {
      // a JavaScript worker
      return EntryPointUri._(workerEntrypoint.toString(), revoke: false);
    } else if (fileName.endsWith('.wasm')) {
      // blob containing the JavaScript code to load and invoke the Web Assembly worker
      final blob = web.Blob(
        [wasmLoaderScript(workerEntrypoint.toString()).toJS].toJS,
        web.BlobPropertyBag(type: 'application/javascript'),
      );
      return EntryPointUri._(web.URL.createObjectURL(blob), revoke: true);
    } else if (workerEntrypoint.isScheme('data') ||
        workerEntrypoint.isScheme('javascript')) {
      // something else, eg. inline JavaScript
      return EntryPointUri._(workerEntrypoint.toString(), revoke: false);
    } else {
      throw SquadronErrorExt.create('Invalid entry point URI');
    }
  }

  static String wasmLoaderScript(String url) => '''(async function() {
  const workerUri = new URL("${url.replaceAll('"', '\\"')}", self.location.origin).href;
  try {
    let dart2wasm_runtime; let moduleInstance;
    const runtimeUri = workerUri.replaceAll('.unopt', '').replaceAll('.wasm', '.mjs');
    try {
      const dartModule = WebAssembly.compileStreaming(fetch(workerUri));
      dart2wasm_runtime = await import(runtimeUri);
      moduleInstance = await dart2wasm_runtime.instantiate(dartModule, {});
    } catch (exception) {
      console.error(`Failed to fetch and instantiate wasm module \${workerUri}: \${exception}`);
      console.error('See https://dart.dev/web/wasm for more information.');
      throw new Error(exception.message ?? 'Unknown error when instantiating worker module');
    }
    try {
      await dart2wasm_runtime.invoke(moduleInstance);
      console.log(`Succesfully loaded and invoked \${workerUri}`);
    } catch (exception) {
      console.error(`Exception while invoking wasm module \${workerUri}: \${exception}`);
      throw new Error(exception.message ?? 'Unknown error when invoking worker module');
    }
  } catch (ex) {
    const ts = (Date.now() - Date.UTC(2020, 1, 2)) * 1000;
    postMessage([ts, null, ["\$sqdrn", `Failed to load Web Worker from \${workerUri}: \${ex}`, null], null, null]);
  }
})()''';
}
