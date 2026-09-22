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
            AB: Object.is,
      AC: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      AD: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
      AE: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      B: s => printToConsole(s),
      BB: (x0,x1) => x0.test(x1),
      BC: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      BD: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
      BE: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      C: (exn) => {
        let stackString = exn.toString();
        let frames = stackString.split('\n');
        let drop = 4;
        if (frames[0].startsWith('Error')) {
            drop += 1;
        }
        return frames.slice(drop).join('\n');
      },
      CB: Function.prototype.call.bind(String.prototype.toLowerCase),
      CC: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      CD: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
      CE: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      D: () => new Error().stack,
      DB: (x0,x1) => x0[x1],
      DC: () => new Array(),
      DD: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
      DE: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      E: Function.prototype.call.bind(Number.prototype.toString),
      EB: (o, p, r) => o.replace(p, () => r),
      EC: (x0,x1,x2) => x0.postMessage(x1,x2),
      ED: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
      EE: (x0,x1) => x0.postMessage(x1),
      F: Function.prototype.call.bind(BigInt.prototype.toString),
      FB: (o, p, r) => o.replaceAll(p, () => r),
      FC: x0 => x0.close(),
      FD: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
      FE: x0 => x0.message,
      G: s => JSON.stringify(s),
      GB: () => {
        return typeof process != "undefined" &&
               Object.prototype.toString.call(process) == "[object process]" &&
               process.platform == "win32"
      },
      GC: x0 => x0.terminate(),
      GD: (constructor, args) => {
        const factoryFunction = constructor.bind.apply(
            constructor, [null, ...args]);
        return new factoryFunction();
      },
      GE: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      H: Function.prototype.call.bind(Number.prototype.toString),
      HB: () => {
        // On browsers return `globalThis.location.href`
        if (globalThis.location != null) {
          return globalThis.location.href;
        }
        return null;
      },
      HC: x0 => globalThis.URL.revokeObjectURL(x0),
      HD: o => [o],
      HE: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      I: Function.prototype.call.bind(String.prototype.indexOf),
      IB: o => String(o),
      IC: (x0,x1) => x0.push(x1),
      ID: (o0, o1) => [o0, o1],
      IE: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      J: o => o,
      JB: x0 => x0.length,
      JC: () => new Map(),
      JD: (o0, o1, o2) => [o0, o1, o2],
      JE: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      K: o => {
        if (o === undefined || o === null) return 0;
        if (typeof o === 'number') return 1;
        return 2;
      },
      KB: s => s.trim(),
      KC: (x0,x1,x2) => x0.set(x1,x2),
      KD: (o0, o1, o2, o3) => [o0, o1, o2, o3],
      KE: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      L: x0 => x0.index,
      LB: (o, p) => p in o,
      LC: () => new Set(),
      LD: () => globalThis,
      LE: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      M: o => o === undefined,
      MB: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
      MC: (x0,x1) => x0.add(x1),
      MD: x0 => globalThis.BigInt(x0),
      ME: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      N: (x0,x1) => x0.exec(x1),
      NB: f => f.dartFunction,
      NC: () => ({}),
      ND: (o, c) => o instanceof c,
      NE: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      O: (x0,x1) => { x0.lastIndex = x1 },
      OB: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      OC: (o, p, v) => o[p] = v,
      OD: x0 => x0.buffer,
      OE: x0 => x0.byteLength,
      P: o => o,
      PB: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      PC: () => [],
      PD: (o) => {
        return o instanceof Object.getPrototypeOf(Int8Array);
      },
      PE: x0 => x0.userAgent,
      Q: (s, m) => {
        try {
          return new RegExp(s, m);
        } catch (e) {
          return String(e);
        }
      },
      QB: (p, s, f) => p.then(s, (e) => f(e, e === undefined)),
      QC: (a, i) => a.push(i),
      QD: (x0,x1) => globalThis.Object.is(x0,x1),
      QE: x0 => x0.navigator,
      R: o => o instanceof RegExp,
      RB: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
      RC: x0 => new Int8Array(x0),
      RD: (x0,x1) => { x0.onmessage = x1 },
      RE: x0 => x0.pop(),
      S: (string, times) => string.repeat(times),
      SB: o => o.buffer,
      SC: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI8ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      SD: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      SE: x0 => x0.flags,
      T: o => o,
      TB: (l, r) => l === r,
      TC: x0 => new Uint8Array(x0),
      TD: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      TE: s => {
        if (/[[\]{}()*+?.\\^$|]/.test(s)) {
            s = s.replace(/[[\]{}()*+?.\\^$|]/g, '\\$&');
        }
        return s;
      },
      U: o => {
        if (o === undefined || o === null) return 0;
        if (typeof o === 'boolean') return 1;
        return 2;
      },
      UB: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
      UC: x0 => new Uint8ClampedArray(x0),
      UD: (x0,x1) => { x0.onmessageerror = x1 },
      UE: (x0,x1) => x0.error(x1),
      V: x0 => x0.dotAll,
      VB: Function.prototype.call.bind(DataView.prototype.setFloat64),
      VC: x0 => new Int16Array(x0),
      VD: (x0,x1) => x0.at(x1),
      VE: () => globalThis.console,
      W: x0 => x0.unicode,
      WB: Function.prototype.call.bind(DataView.prototype.getFloat64),
      WC: x0 => new Uint16Array(x0),
      WD: x0 => x0.entries(),
      WE: x0 => x0.pathname,
      X: x0 => x0.ignoreCase,
      XB: Function.prototype.call.bind(DataView.prototype.getFloat32),
      XC: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI16ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      XD: x0 => x0.values(),
      XE: o => {
        const proto = Object.getPrototypeOf(o);
        return proto === Object.prototype || proto === null;
      },
      Y: x0 => x0.multiline,
      YB: Function.prototype.call.bind(DataView.prototype.setFloat32),
      YC: x0 => new Int32Array(x0),
      YD: (o) => !!o,
      YE: o => Object.keys(o),
      Z: (exn) => {
        if (exn instanceof Error) {
          return exn.stack;
        } else {
          return null;
        }
      },
      ZB: Function.prototype.call.bind(DataView.prototype.setUint32),
      ZC: x0 => new Uint32Array(x0),
      ZD: (o, m, a) => o[m].apply(o, a),
      ZE: x0 => x0.data,
      a: (c) =>
      queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
      aB: Function.prototype.call.bind(DataView.prototype.getUint32),
      aC: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      aD: x0 => x0.length,
      aE: (o, p, v) => o[p] = v,
      b: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      bB: Function.prototype.call.bind(DataView.prototype.getInt32),
      bC: x0 => new Float32Array(x0),
      bD: x0 => x0.toString(),
      bE: (x0,x1) => x0.getElementsByClassName(x1),
      c: (x0,x1,x2) => x0.postMessage(x1,x2),
      cB: Function.prototype.call.bind(DataView.prototype.setInt32),
      cC: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      cD: x0 => x0.getTime(),
      cE: x0 => x0.innerText,
      d: x0 => x0.origin,
      dB: Function.prototype.call.bind(DataView.prototype.getUint16),
      dC: x0 => new Float64Array(x0),
      dD: s => new Date(s * 1000).getTimezoneOffset() * 60,
      dE: (x0,x1) => x0.item(x1),
      e: x0 => x0.location,
      eB: Function.prototype.call.bind(DataView.prototype.setUint16),
      eC: x0 => new ArrayBuffer(x0),
      eD: (o, t) => typeof o === t,
      eE: x0 => x0.length,
      f: x0 => x0.parent,
      fB: Function.prototype.call.bind(DataView.prototype.getInt16),
      fC: (x0,x1,x2) => new Uint8Array(x0,x1,x2),
      fD: (x0,x1,x2) => x0.postMessage(x1,x2),
      fE: (x0,x1) => x0.createElement(x1),
      g: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
      gB: Function.prototype.call.bind(DataView.prototype.setInt16),
      gC: (x0,x1,x2) => new DataView(x0,x1,x2),
      gD: (x0,x1) => x0.postMessage(x1),
      gE: () => globalThis.window,
      h: b => !!b,
      hB: Function.prototype.call.bind(DataView.prototype.getUint8),
      hC: (o, p) => o[p],
      hD: Date.now,
      hE: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      i: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      iB: Function.prototype.call.bind(DataView.prototype.setUint8),
      iC: (b, o) => new DataView(b, o),
      iD: x0 => x0.port1,
      iE: (x0,x1) => { x0.onscroll = x1 },
      j: x0 => x0.random(),
      jB: Function.prototype.call.bind(DataView.prototype.getInt8),
      jC: (b, o, l) => new DataView(b, o, l),
      jD: x0 => x0.port2,
      jE: x0 => x0.clientHeight,
      k: () => globalThis.Math,
      kB: Function.prototype.call.bind(DataView.prototype.setInt8),
      kC: x0 => new Array(x0),
      kD: (x0,x1) => { x0.onmessage = x1 },
      kE: x0 => x0.scrollTop,
      l: (s, p, i) => s.lastIndexOf(p, i),
      lB: (o, i) => o[i],
      lC: (x0,x1,x2) => { x0[x1] = x2 },
      lD: (x0,x1) => { x0.onmessageerror = x1 },
      lE: (x0,x1) => x0.querySelector(x1),
      m: (x0,x1) => x0.remove(x1),
      mB: o => o.length,
      mC: o => o.byteOffset,
      mD: (x0,x1) => { x0.onerror = x1 },
      mE: () => globalThis.document,
      n: (x0,x1) => x0.add(x1),
      nB: o => {
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
      nC: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Float64Array) return 1;
        return 2;
      },
      nD: x0 => x0.lineno,
      nE: (a, i) => a[i],
      o: x0 => x0.scrollIntoView(),
      oB: (o, p) => o[p],
      oC: (t, s) => t.set(s),
      oD: x0 => x0.filename,
      oE: a => a.length,
      p: x0 => x0.classList,
      pB: x0 => x0.groups,
      pC: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Float32Array) return 1;
        return 2;
      },
      pD: (x0,x1) => globalThis.fetch(x0,x1),
      pE: o => o instanceof Array,
      q: x0 => x0.parentElement,
      qB: (string, token) => string.split(token),
      qC: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Uint32Array) return 1;
        return 2;
      },
      qD: x0 => x0.status,
      qE: (a, s, e) => a.slice(s, e),
      r: (x0,x1) => { x0.innerHTML = x1 },
      rB: (handle) => clearTimeout(handle),
      rC: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Int32Array) return 1;
        return 2;
      },
      rD: x0 => x0.ok,
      rE: (a, i, v) => a[i] = v,
      s: (x0,x1) => x0.appendChild(x1),
      sB: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      sC: o => o instanceof Uint16Array,
      sD: x0 => ({type: x0}),
      sE: (a, l) => a.length = l,
      t: (x0,x1,x2) => x0.scrollTo(x1,x2),
      tB: (x0,x1,x2,x3) => x0.removeEventListener(x1,x2,x3),
      tC: o => o instanceof Int16Array,
      tD: (x0,x1) => new Blob(x0,x1),
      tE: (a, i) => a.splice(i, 1),
      u: x0 => x0.scrollHeight,
      uB: () => typeof dartUseDateNowForTicks !== "undefined",
      uC: o => o instanceof Uint8ClampedArray,
      uD: x0 => globalThis.URL.createObjectURL(x0),
      uE: (a, i) => a.splice(i, 1)[0],
      v: (handle) => clearInterval(handle),
      vB: () => Date.now(),
      vC: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Uint8Array) return 1;
        return 2;
      },
      vD: (x0,x1) => x0.getRandomValues(x1),
      vE: a => a.pop(),
      w: (ms, c) =>
      setInterval(() => dartInstance.exports.$invokeCallback(c), ms),
      wB: () => 1000 * performance.now(),
      wC: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Int8Array) return 1;
        return 2;
      },
      wD: () => globalThis.crypto,
      wE: (a, s, e) => a.splice(s, e),
      x: () => Date.now(),
      xB: () => new MessageChannel(),
      xC: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
      xD: l => new DataView(new ArrayBuffer(l)),
      xE: (a, l) => a.length = l,
      y: (ms, c) =>
      setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
      yB: x0 => new Worker(x0),
      yC: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
      yD: s => s.trimRight(),
      yE: (a, b) => a == b ? 0 : (a > b ? 1 : -1),
      z: s => s.toUpperCase(),
      zB: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      zC: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
      zD: (o, offsetInBytes, lengthInBytes) => {
        var dst = new ArrayBuffer(lengthInBytes);
        new Uint8Array(dst).set(new Uint8Array(o, offsetInBytes, lengthInBytes));
        return new DataView(dst);
      },
      zE: (a, s) => a.join(s),

    };

    const baseImports = {
      dart2wasm: dart2wasm,
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
