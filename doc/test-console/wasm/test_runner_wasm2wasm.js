(async function(){
  let newRt = false;
  try {
    let d2w_rt; let worker;
    try {
      const wasm = fetch('./wasm/runner_wasm_workers.dart.wasm');
      d2w_rt = await import('./runner_wasm_workers.dart.mjs');
      newRt = (typeof d2w_rt.compileStreaming === 'function');
      worker = await (newRt
        ? (await d2w_rt.compileStreaming(wasm)).instantiate({})
        : d2w_rt.instantiate(WebAssembly.compileStreaming(wasm), {})
      );
    } catch (exception) {
      console.error(
        `Failed to fetch and instantiate wasm module \${workerUri}: \${exception}\n`+
        "See https://dart.dev/web/wasm for more information."
      );
      throw new Error(exception.message ?? 'Unknown error when instantiating worker module');
    }
    try {
      await (newRt ? worker.invokeMain() : d2w_rt.invoke(worker));
    } catch (exception) {
      console.error(`Exception while invoking wasm module: \${exception}`);
      throw new Error(exception.message ?? 'Unknown error when invoking worker module');
    }
  } catch (ex) {
    console.error(`Exception while invoking test: ${exception}`);
  }
})()
