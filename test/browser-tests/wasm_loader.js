(async function () {
    const url = new URL(self.location);
    const worker = url.searchParams.get("worker");
    const unopt = url.searchParams.has("unopt") ? ".unopt" : "";
    let dart2wasm_runtime;
    let moduleInstance;
    try {
        const dartModulePromise = WebAssembly.compileStreaming(fetch(`${worker}${unopt}.wasm`));
        const imports = {};
        dart2wasm_runtime = await import(`${worker}.mjs`);
        moduleInstance = await dart2wasm_runtime.instantiate(dartModulePromise, imports);
    } catch (exception) {
        console.error(`Failed to fetch and instantiate wasm module: ${exception}`);
        console.error('See https://dart.dev/web/wasm for more information.');
        postMessage({ "ready": false });
    }

    if (moduleInstance) {
        try {
            await dart2wasm_runtime.invoke(moduleInstance);
        } catch (exception) {
            console.error(`Exception while invoking test: ${exception}`);
            postMessage({ "ready": false });
        }
    }
})();