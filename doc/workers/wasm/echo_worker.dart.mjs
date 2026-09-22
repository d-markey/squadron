// Compiles a dart2wasm-generated main module from `source` which can then
// be instantiated via the `instantiate` method.
//
// `source` needs to be a `Response` object (or promise thereof) e.g. created
// via the `fetch()` JS API.
export async function compileStreaming(source) {
  const builtins = {builtins: ['js-string']};
  return new CompiledApp(
      await WebAssembly.compileStreaming(source, builtins), builtins);
}

// Compiles a dart2wasm-generated wasm module from `bytes` which is then
// instantiable via the `instantiate` method.
export async function compile(bytes) {
  const builtins = {builtins: ['js-string']};
  return new CompiledApp(await WebAssembly.compile(bytes, builtins), builtins);
}

class CompiledApp {
  constructor(module, builtins) {
    this.module = module;
    this.builtins = builtins;
  }

  // The second argument is an options object containing:
  // `loadDeferredModules` is a JS function that takes an array of module names
  //   matching wasm files produced by the dart2wasm compiler. It also takes a
  //   callback that should be invoked for each loaded module with 2 arguments:
  //   (1) the module name, (2) the loaded module in a format supported by
  //   `WebAssembly.compile` or `WebAssembly.compileStreaming`. The callback
  //   returns a Promise that resolves when the module is instantiated.
  //   loadDeferredModules should return a Promise that resolves when all the
  //   modules have been loaded and the callback promises have resolved.
  // `loadDeferredId` is a JS function that takes load ID produced by the
  //   compiler when the `use-load-ids` option is passed. Each load ID maps to
  //   one or more wasm files as specified in the emitted JSON file. It also
  //   takes a callback that should be invoked for each loaded module with 2
  //   arguments: (1) the module name, (2) the loaded module in a format
  //   supported by `WebAssembly.compile` or `WebAssembly.compileStreaming`.
  //   The callback returns a Promise that resolves when the module is
  //   instantiated.
  //   loadDeferredId should return a Promise that resolves when all the
  //   modules have been loaded and the callback promises have resolved.
  async instantiate(additionalImports, {loadDeferredModules, loadDeferredId} = {}) {
    let dartInstance;

    // Prints to the console
    function printToConsole(value) {
      if (typeof dartPrint == "function") {
        dartPrint(value);
        return;
      }
      if (typeof console == "object" && typeof console.log != "undefined") {
        console.log(value);
        return;
      }
      if (typeof print == "function") {
        print(value);
        return;
      }

      throw "Unable to print message: " + value;
    }

    // A special symbol attached to functions that wrap Dart functions.
    const jsWrappedDartFunctionSymbol = Symbol("JSWrappedDartFunction");

    function finalizeWrapper(dartFunction, wrapped) {
      wrapped.dartFunction = dartFunction;
      wrapped[jsWrappedDartFunctionSymbol] = true;
      return wrapped;
    }

    // Imports
    const dart2wasm = {
            AB: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Float32Array) return 1;
        return 2;
      },
      B: s => printToConsole(s),
      BB: Function.prototype.call.bind(DataView.prototype.getUint32),
      C: Function.prototype.call.bind(Number.prototype.toString),
      CB: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Uint32Array) return 1;
        return 2;
      },
      D: Function.prototype.call.bind(String.prototype.indexOf),
      DB: Function.prototype.call.bind(DataView.prototype.getInt32),
      E: (exn) => {
        let stackString = exn.toString();
        let frames = stackString.split('\n');
        let drop = 4;
        if (frames[0].startsWith('Error')) {
            drop += 1;
        }
        return frames.slice(drop).join('\n');
      },
      EB: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Int32Array) return 1;
        return 2;
      },
      F: () => new Error().stack,
      FB: o => o instanceof Uint16Array,
      G: s => JSON.stringify(s),
      GB: Function.prototype.call.bind(DataView.prototype.getUint16),
      H: (s, p, i) => s.lastIndexOf(p, i),
      HB: o => o instanceof Int16Array,
      I: Function.prototype.call.bind(Number.prototype.toString),
      IB: Function.prototype.call.bind(DataView.prototype.getInt16),
      J: Function.prototype.call.bind(BigInt.prototype.toString),
      JB: o => o instanceof Uint8ClampedArray,
      K: (exn) => {
        if (exn instanceof Error) {
          return exn.stack;
        } else {
          return null;
        }
      },
      KB: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Uint8Array) return 1;
        return 2;
      },
      L: o => o === undefined,
      LB: Function.prototype.call.bind(DataView.prototype.setInt32),
      M: o => String(o),
      MB: Function.prototype.call.bind(DataView.prototype.setUint32),
      N: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      NB: Function.prototype.call.bind(DataView.prototype.setInt16),
      O: (x0,x1) => x0.postMessage(x1),
      OB: Function.prototype.call.bind(DataView.prototype.setUint16),
      P: () => ({}),
      PB: Function.prototype.call.bind(DataView.prototype.setUint8),
      Q: (o, p, v) => o[p] = v,
      QB: Function.prototype.call.bind(DataView.prototype.setInt8),
      R: () => [],
      RB: Function.prototype.call.bind(DataView.prototype.getInt8),
      S: (a, i) => a.push(i),
      SB: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Int8Array) return 1;
        return 2;
      },
      T: x0 => x0.random(),
      TB: o => o,
      U: o => o,
      UB: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
      V: o => {
        if (o === undefined || o === null) return 0;
        if (typeof o === 'number') return 1;
        return 2;
      },
      VB: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
      W: () => globalThis.Math,
      WB: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
      X: b => !!b,
      XB: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
      Y: x0 => new Int8Array(x0),
      YB: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
      Z: x0 => new Uint8Array(x0),
      ZB: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
      a: x0 => new Uint8ClampedArray(x0),
      aB: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
      b: x0 => new Int16Array(x0),
      bB: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
      c: x0 => new Uint16Array(x0),
      cB: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
      d: x0 => new Int32Array(x0),
      dB: s => new Date(s * 1000).getTimezoneOffset() * 60,
      e: x0 => new Uint32Array(x0),
      eB: Date.now,
      f: x0 => new Float32Array(x0),
      fB: (x0,x1) => { x0.onmessage = x1 },
      g: x0 => new Float64Array(x0),
      gB: o => {
        const proto = Object.getPrototypeOf(o);
        return proto === Object.prototype || proto === null;
      },
      h: x0 => new ArrayBuffer(x0),
      hB: o => Object.keys(o),
      i: (x0,x1,x2) => new Uint8Array(x0,x1,x2),
      iB: o => o,
      j: (x0,x1,x2) => new DataView(x0,x1,x2),
      jB: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
      k: (o, p) => o[p],
      kB: f => f.dartFunction,
      l: (b, o) => new DataView(b, o),
      lB: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      m: (b, o, l) => new DataView(b, o, l),
      mB: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      n: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
      nB: (p, s, f) => p.then(s, (e) => f(e, e === undefined)),
      o: x0 => new Array(x0),
      oB: (c) =>
      queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
      p: (x0,x1,x2) => { x0[x1] = x2 },
      pB: (o, i) => o[i],
      q: o => o.byteOffset,
      qB: (o, p) => o[p],
      r: Function.prototype.call.bind(DataView.prototype.getUint8),
      rB: (l, r) => l === r,
      s: o => o.buffer,
      sB: o => o.length,
      t: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
      tB: o => {
        if (o === undefined) return 1;
        var type = typeof o;
        if (type === 'boolean') return 2;
        if (type === 'number') return 3;
        if (type === 'string') return 4;
        if (o instanceof Array) return 5;
        if (ArrayBuffer.isView(o)) {
          if (o instanceof Int8Array) return 6;
          if (o instanceof Uint8Array) return 7;
          if (o instanceof Uint8ClampedArray) return 8;
          if (o instanceof Int16Array) return 9;
          if (o instanceof Uint16Array) return 10;
          if (o instanceof Int32Array) return 11;
          if (o instanceof Uint32Array) return 12;
          if (o instanceof Float32Array) return 13;
          if (o instanceof Float64Array) return 14;
          if (o instanceof DataView) return 15;
        }
        if (o instanceof ArrayBuffer) return 16;
        // Feature check for `SharedArrayBuffer` before doing a type-check.
        if (globalThis.SharedArrayBuffer !== undefined &&
            o instanceof SharedArrayBuffer) {
            return 17;
        }
        if (o instanceof Promise) return 18;
        return 19;
      },
      u: Function.prototype.call.bind(DataView.prototype.getFloat64),
      uB: x0 => x0.data,
      v: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Float64Array) return 1;
        return 2;
      },
      vB: () => globalThis.self,
      w: Function.prototype.call.bind(DataView.prototype.setFloat64),
      x: (t, s) => t.set(s),
      y: Function.prototype.call.bind(DataView.prototype.setFloat32),
      z: Function.prototype.call.bind(DataView.prototype.getFloat32),

    };

    const baseImports = {
      _: dart2wasm,
      Math: Math,
      Date: Date,
      Object: Object,
      Array: Array,
      Reflect: Reflect,
      WebAssembly: {
        JSTag: WebAssembly.JSTag,
      },
      "": new Proxy({}, { get(_, prop) { return prop; } }),

    };

    const jsStringPolyfill = {
      "charCodeAt": (s, i) => s.charCodeAt(i),
      "compare": (s1, s2) => {
        if (s1 < s2) return -1;
        if (s1 > s2) return 1;
        return 0;
      },
      "concat": (s1, s2) => s1 + s2,
      "equals": (s1, s2) => s1 === s2,
      "fromCharCode": (i) => String.fromCharCode(i),
      "length": (s) => s.length,
      "substring": (s, a, b) => s.substring(a, b),
      "fromCharCodeArray": (a, start, end) => {
        if (end <= start) return '';

        const read = dartInstance.exports.$wasmI16ArrayGet;
        let result = '';
        let index = start;
        const chunkLength = Math.min(end - index, 500);
        let array = new Array(chunkLength);
        while (index < end) {
          const newChunkLength = Math.min(end - index, 500);
          for (let i = 0; i < newChunkLength; i++) {
            array[i] = read(a, index++);
          }
          if (newChunkLength < chunkLength) {
            array = array.slice(0, newChunkLength);
          }
          result += String.fromCharCode(...array);
        }
        return result;
      },
      "intoCharCodeArray": (s, a, start) => {
        if (s === '') return 0;

        const write = dartInstance.exports.$wasmI16ArraySet;
        for (var i = 0; i < s.length; ++i) {
          write(a, start++, s.charCodeAt(i));
        }
        return s.length;
      },
      "test": (s) => typeof s == "string",
    };


    

    dartInstance = await WebAssembly.instantiate(this.module, {
      ...baseImports,
      ...additionalImports,
      
      "wasm:js-string": jsStringPolyfill,
    });

    return new InstantiatedApp(this, dartInstance);
  }
}

class InstantiatedApp {
  constructor(compiledApp, instantiatedModule) {
    this.compiledApp = compiledApp;
    this.instantiatedModule = instantiatedModule;
  }

  // Call the main function with the given arguments.
  invokeMain(...args) {
    this.instantiatedModule.exports.$invokeMain(args);
  }
}
