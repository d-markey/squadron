(async function () {
    let dart2wasm_runtime;
    let moduleInstance;
    try {
        const dartModulePromise = WebAssembly.compileStreaming(fetch('./wasm/runner_js_workers.dart.wasm'));
        const imports = {};
        dart2wasm_runtime = await import('./runner_js_workers.dart.mjs');
        moduleInstance = await dart2wasm_runtime.instantiate(dartModulePromise, imports);
    } catch (exception) {
        console.error(`Failed to fetch and instantiate wasm module: ${exception}`);
        console.error('See https://dart.dev/web/wasm for more information.');
    }

    if (moduleInstance) {
        try {
            await dart2wasm_runtime.invoke(moduleInstance);
        } catch (exception) {
            console.error(`Exception while invoking test: ${exception}`);
        }
    }
})();