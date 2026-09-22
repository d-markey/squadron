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
            AB: Function.prototype.call.bind(DataView.prototype.getFloat64),
      AC: o => o,
      B: s => printToConsole(s),
      BB: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Float64Array) return 1;
        return 2;
      },
      BC: o => {
        if (o === undefined || o === null) return 0;
        if (typeof o === 'boolean') return 1;
        return 2;
      },
      C: Function.prototype.call.bind(Number.prototype.toString),
      CB: Function.prototype.call.bind(DataView.prototype.setFloat64),
      CC: s => new Date(s * 1000).getTimezoneOffset() * 60,
      D: Function.prototype.call.bind(BigInt.prototype.toString),
      DB: (t, s) => t.set(s),
      DC: Date.now,
      E: (exn) => {
        let stackString = exn.toString();
        let frames = stackString.split('\n');
        let drop = 4;
        if (frames[0].startsWith('Error')) {
            drop += 1;
        }
        return frames.slice(drop).join('\n');
      },
      EB: Function.prototype.call.bind(DataView.prototype.setFloat32),
      EC: (x0,x1) => { x0.onmessage = x1 },
      F: () => new Error().stack,
      FB: Function.prototype.call.bind(DataView.prototype.getFloat32),
      FC: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      G: s => JSON.stringify(s),
      GB: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Float32Array) return 1;
        return 2;
      },
      GC: (c) =>
      queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
      H: Function.prototype.call.bind(Number.prototype.toString),
      HB: Function.prototype.call.bind(DataView.prototype.getUint32),
      HC: x0 => x0.close(),
      I: Function.prototype.call.bind(String.prototype.indexOf),
      IB: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Uint32Array) return 1;
        return 2;
      },
      IC: x0 => x0.close(),
      J: (s, p, i) => s.lastIndexOf(p, i),
      JB: Function.prototype.call.bind(DataView.prototype.getInt32),
      JC: (x0,x1) => x0.postMessage(x1),
      K: (exn) => {
        if (exn instanceof Error) {
          return exn.stack;
        } else {
          return null;
        }
      },
      KB: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Int32Array) return 1;
        return 2;
      },
      KC: (x0,x1,x2) => x0.postMessage(x1,x2),
      L: o => o === undefined,
      LB: o => o instanceof Uint16Array,
      LC: (ms, c) =>
      setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
      M: o => String(o),
      MB: Function.prototype.call.bind(DataView.prototype.getUint16),
      MC: (string, times) => string.repeat(times),
      N: () => new MessageChannel(),
      NB: o => o instanceof Int16Array,
      NC: (a, i, v) => a[i] = v,
      O: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      OB: Function.prototype.call.bind(DataView.prototype.getInt16),
      OC: x0 => x0.port2,
      P: () => new Array(),
      PB: o => o instanceof Uint8ClampedArray,
      PC: (x0,x1) => x0.at(x1),
      Q: (x0,x1,x2) => x0.postMessage(x1,x2),
      QB: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Uint8Array) return 1;
        return 2;
      },
      QC: x0 => x0.entries(),
      R: (x0,x1) => x0.push(x1),
      RB: Function.prototype.call.bind(DataView.prototype.setInt32),
      RC: x0 => x0.values(),
      S: () => new Map(),
      SB: Function.prototype.call.bind(DataView.prototype.setUint32),
      SC: o => {
        const proto = Object.getPrototypeOf(o);
        return proto === Object.prototype || proto === null;
      },
      T: (x0,x1,x2) => x0.set(x1,x2),
      TB: Function.prototype.call.bind(DataView.prototype.setInt16),
      TC: o => Object.keys(o),
      U: () => new Set(),
      UB: Function.prototype.call.bind(DataView.prototype.setUint16),
      UC: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
      V: (x0,x1) => x0.add(x1),
      VB: Function.prototype.call.bind(DataView.prototype.setUint8),
      VC: f => f.dartFunction,
      W: () => ({}),
      WB: Function.prototype.call.bind(DataView.prototype.setInt8),
      WC: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      X: (o, p, v) => o[p] = v,
      XB: Function.prototype.call.bind(DataView.prototype.getInt8),
      XC: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      Y: () => [],
      YB: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Int8Array) return 1;
        return 2;
      },
      YC: (p, s, f) => p.then(s, (e) => f(e, e === undefined)),
      Z: (a, i) => a.push(i),
      ZB: o => o,
      ZC: o => o.byteOffset,
      a: x0 => x0.random(),
      aB: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
      aC: o => o.buffer,
      b: o => o,
      bB: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
      bC: (o, i) => o[i],
      c: o => {
        if (o === undefined || o === null) return 0;
        if (typeof o === 'number') return 1;
        return 2;
      },
      cB: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
      cC: o => o.length,
      d: () => globalThis.Math,
      dB: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
      dC: o => {
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
      e: b => !!b,
      eB: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
      eC: (o) => !!o,
      f: x0 => new Int8Array(x0),
      fB: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
      fC: (o, m, a) => o[m].apply(o, a),
      g: x0 => new Uint8Array(x0),
      gB: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
      gC: x0 => x0.length,
      h: x0 => new Uint8ClampedArray(x0),
      hB: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
      hC: x0 => x0.toString(),
      i: x0 => new Int16Array(x0),
      iB: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
      iC: x0 => x0.getTime(),
      j: x0 => new Uint16Array(x0),
      jB: (l, r) => l === r,
      jC: (x0,x1) => x0[x1],
      k: x0 => new Int32Array(x0),
      kB: (constructor, args) => {
        const factoryFunction = constructor.bind.apply(
            constructor, [null, ...args]);
        return new factoryFunction();
      },
      kC: x0 => x0.length,
      l: x0 => new Uint32Array(x0),
      lB: o => [o],
      lC: (x0,x1) => x0.exec(x1),
      m: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      mB: (o0, o1) => [o0, o1],
      mC: x0 => x0.flags,
      n: x0 => new Float32Array(x0),
      nB: (o0, o1, o2) => [o0, o1, o2],
      nC: (s, m) => {
        try {
          return new RegExp(s, m);
        } catch (e) {
          return String(e);
        }
      },
      o: x0 => new Float64Array(x0),
      oB: (o0, o1, o2, o3) => [o0, o1, o2, o3],
      oC: o => o instanceof RegExp,
      p: x0 => new ArrayBuffer(x0),
      pB: (o, p) => o[p],
      pC: (o, t) => typeof o === t,
      q: (x0,x1,x2) => new Uint8Array(x0,x1,x2),
      qB: () => globalThis,
      qC: (x0,x1) => { x0.onmessage = x1 },
      r: (x0,x1,x2) => new DataView(x0,x1,x2),
      rB: x0 => globalThis.BigInt(x0),
      rC: x0 => x0.port1,
      s: (o, p) => o[p],
      sB: (o, c) => o instanceof c,
      sC: () => globalThis.self,
      t: x0 => new Array(x0),
      tB: (string, token) => string.split(token),
      u: (x0,x1,x2) => { x0[x1] = x2 },
      uB: o => o instanceof Array,
      v: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
      vB: (a, i) => a[i],
      w: Function.prototype.call.bind(DataView.prototype.getUint8),
      wB: a => a.length,
      x: (b, o) => new DataView(b, o),
      xB: x0 => x0.buffer,
      y: (b, o, l) => new DataView(b, o, l),
      yB: (o) => {
        return o instanceof Object.getPrototypeOf(Int8Array);
      },
      z: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
      zB: (x0,x1) => globalThis.Object.is(x0,x1),

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
