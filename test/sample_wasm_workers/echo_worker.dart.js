(async function () {
    self.sqId = 1;

    console.log(`starting echo_worker.dart.js with self = ${self} #${self.sqId}...`);

    let dart2wasm_runtime;
    let moduleInstance;
    try {
        const dartModulePromise = WebAssembly.compileStreaming(fetch('echo_worker.dart.wasm'));
        const imports = {};
        dart2wasm_runtime = await import('./echo_worker.dart.mjs');
        moduleInstance = await dart2wasm_runtime.instantiate(dartModulePromise, imports);
    } catch (exception) {
        console.error(`Failed to fetch and instantiate wasm module: ${exception}`);
        console.error('See https://dart.dev/web/wasm for more information.');
    }

    if (moduleInstance) {
        try {
            await dart2wasm_runtime.invoke(moduleInstance);
            console.log(`echo_worker.dart.js ready with self = ${self} #${self.sqId}...`);
        } catch (exception) {
            console.error(`Exception while invoking test: ${exception}`);
        }
    }
})();