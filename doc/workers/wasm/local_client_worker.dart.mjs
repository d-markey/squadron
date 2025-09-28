// Compiles a dart2wasm-generated main module from `source` which can then
// instantiatable via the `instantiate` method.
//
// `source` needs to be a `Response` object (or promise thereof) e.g. created
// via the `fetch()` JS API.
export async function compileStreaming(source) {
  const builtins = {builtins: ['js-string']};
  return new CompiledApp(
      await WebAssembly.compileStreaming(source, builtins), builtins);
}

// Compiles a dart2wasm-generated wasm modules from `bytes` which is then
// instantiatable via the `instantiate` method.
export async function compile(bytes) {
  const builtins = {builtins: ['js-string']};
  return new CompiledApp(await WebAssembly.compile(bytes, builtins), builtins);
}

// DEPRECATED: Please use `compile` or `compileStreaming` to get a compiled app,
// use `instantiate` method to get an instantiated app and then call
// `invokeMain` to invoke the main function.
export async function instantiate(modulePromise, importObjectPromise) {
  var moduleOrCompiledApp = await modulePromise;
  if (!(moduleOrCompiledApp instanceof CompiledApp)) {
    moduleOrCompiledApp = new CompiledApp(moduleOrCompiledApp);
  }
  const instantiatedApp = await moduleOrCompiledApp.instantiate(await importObjectPromise);
  return instantiatedApp.instantiatedModule;
}

// DEPRECATED: Please use `compile` or `compileStreaming` to get a compiled app,
// use `instantiate` method to get an instantiated app and then call
// `invokeMain` to invoke the main function.
export const invoke = (moduleInstance, ...args) => {
  moduleInstance.exports.$invokeMain(args);
}

class CompiledApp {
  constructor(module, builtins) {
    this.module = module;
    this.builtins = builtins;
  }

  // The second argument is an options object containing:
  // `loadDeferredWasm` is a JS function that takes a module name matching a
  //   wasm file produced by the dart2wasm compiler and returns the bytes to
  //   load the module. These bytes can be in either a format supported by
  //   `WebAssembly.compile` or `WebAssembly.compileStreaming`.
  // `loadDynamicModule` is a JS function that takes two string names matching,
  //   in order, a wasm file produced by the dart2wasm compiler during dynamic
  //   module compilation and a corresponding js file produced by the same
  //   compilation. It should return a JS Array containing 2 elements. The first
  //   should be the bytes for the wasm module in a format supported by
  //   `WebAssembly.compile` or `WebAssembly.compileStreaming`. The second
  //   should be the result of using the JS 'import' API on the js file path.
  async instantiate(additionalImports, {loadDeferredWasm, loadDynamicModule} = {}) {
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
            _3: (o, t) => typeof o === t,
      _4: (o, c) => o instanceof c,
      _27: (o) => !!o,
      _36: () => new Array(),
      _37: x0 => new Array(x0),
      _39: x0 => x0.length,
      _41: (x0,x1) => x0[x1],
      _42: (x0,x1,x2) => { x0[x1] = x2 },
      _45: (x0,x1,x2) => new DataView(x0,x1,x2),
      _47: x0 => new Int8Array(x0),
      _48: (x0,x1,x2) => new Uint8Array(x0,x1,x2),
      _49: x0 => new Uint8Array(x0),
      _51: x0 => new Uint8ClampedArray(x0),
      _53: x0 => new Int16Array(x0),
      _55: x0 => new Uint16Array(x0),
      _57: x0 => new Int32Array(x0),
      _59: x0 => new Uint32Array(x0),
      _61: x0 => new Float32Array(x0),
      _63: x0 => new Float64Array(x0),
      _74: Date.now,
      _76: s => new Date(s * 1000).getTimezoneOffset() * 60,
      _78: () => {
        let stackString = new Error().stack.toString();
        let frames = stackString.split('\n');
        let drop = 2;
        if (frames[0] === 'Error') {
            drop += 1;
        }
        return frames.slice(drop).join('\n');
      },
      _99: s => JSON.stringify(s),
      _100: s => printToConsole(s),
      _103: Function.prototype.call.bind(String.prototype.toLowerCase),
      _108: (string, times) => string.repeat(times),
      _109: Function.prototype.call.bind(String.prototype.indexOf),
      _110: (s, p, i) => s.lastIndexOf(p, i),
      _111: (string, token) => string.split(token),
      _112: Object.is,
      _113: o => o instanceof Array,
      _124: a => a.length,
      _126: (a, i) => a[i],
      _127: (a, i, v) => a[i] = v,
      _132: o => o instanceof Uint8Array,
      _133: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
      _134: o => o instanceof Int8Array,
      _135: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
      _136: o => o instanceof Uint8ClampedArray,
      _137: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
      _138: o => o instanceof Uint16Array,
      _139: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
      _140: o => o instanceof Int16Array,
      _141: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
      _142: o => o instanceof Uint32Array,
      _143: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
      _144: o => o instanceof Int32Array,
      _145: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
      _148: o => o instanceof Float32Array,
      _149: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
      _150: o => o instanceof Float64Array,
      _151: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
      _152: (t, s) => t.set(s),
      _153: l => new DataView(new ArrayBuffer(l)),
      _154: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
      _156: o => o.buffer,
      _157: o => o.byteOffset,
      _158: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
      _159: (b, o) => new DataView(b, o),
      _160: (b, o, l) => new DataView(b, o, l),
      _161: Function.prototype.call.bind(DataView.prototype.getUint8),
      _162: Function.prototype.call.bind(DataView.prototype.setUint8),
      _163: Function.prototype.call.bind(DataView.prototype.getInt8),
      _164: Function.prototype.call.bind(DataView.prototype.setInt8),
      _165: Function.prototype.call.bind(DataView.prototype.getUint16),
      _166: Function.prototype.call.bind(DataView.prototype.setUint16),
      _167: Function.prototype.call.bind(DataView.prototype.getInt16),
      _168: Function.prototype.call.bind(DataView.prototype.setInt16),
      _169: Function.prototype.call.bind(DataView.prototype.getUint32),
      _170: Function.prototype.call.bind(DataView.prototype.setUint32),
      _171: Function.prototype.call.bind(DataView.prototype.getInt32),
      _172: Function.prototype.call.bind(DataView.prototype.setInt32),
      _177: Function.prototype.call.bind(DataView.prototype.getFloat32),
      _178: Function.prototype.call.bind(DataView.prototype.setFloat32),
      _179: Function.prototype.call.bind(DataView.prototype.getFloat64),
      _180: Function.prototype.call.bind(DataView.prototype.setFloat64),
      _197: (c) =>
      queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
      _203: o => Object.keys(o),
      _227: (x0,x1,x2) => x0.postMessage(x1,x2),
      _228: x0 => x0.close(),
      _229: () => new MessageChannel(),
      _230: (x0,x1) => x0.push(x1),
      _231: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._231(f,arguments.length,x0) }),
      _232: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._232(f,arguments.length,x0) }),
      _241: () => globalThis.self,
      _242: x0 => x0.close(),
      _243: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._243(f,arguments.length,x0) }),
      _244: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._244(f,arguments.length,x0) }),
      _245: (x0,x1,x2) => x0.postMessage(x1,x2),
      _246: (x0,x1) => x0.postMessage(x1),
      _251: (x0,x1) => globalThis.Object.is(x0,x1),
      _252: (x0,x1) => x0.at(x1),
      _253: x0 => x0.entries(),
      _254: x0 => x0.values(),
      _255: x0 => globalThis.BigInt(x0),
      _256: () => new Map(),
      _257: (x0,x1,x2) => x0.set(x1,x2),
      _258: () => new Set(),
      _259: (x0,x1) => x0.add(x1),
      _260: x0 => x0.toString(),
      _261: x0 => x0.getTime(),
      _262: x0 => x0.length,
      _264: x0 => x0.buffer,
      _277: (s, m) => {
        try {
          return new RegExp(s, m);
        } catch (e) {
          return String(e);
        }
      },
      _278: (x0,x1) => x0.exec(x1),
      _282: o => o === undefined,
      _284: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
      _286: o => {
        const proto = Object.getPrototypeOf(o);
        return proto === Object.prototype || proto === null;
      },
      _287: o => o instanceof RegExp,
      _288: (l, r) => l === r,
      _289: o => o,
      _290: o => o,
      _291: o => o,
      _292: b => !!b,
      _293: o => o.length,
      _295: (o, i) => o[i],
      _296: f => f.dartFunction,
      _297: () => ({}),
      _298: () => [],
      _300: () => globalThis,
      _301: (constructor, args) => {
        const factoryFunction = constructor.bind.apply(
            constructor, [null, ...args]);
        return new factoryFunction();
      },
      _303: (o, p) => o[p],
      _304: (o, p, v) => o[p] = v,
      _305: (o, m, a) => o[m].apply(o, a),
      _307: o => String(o),
      _309: o => {
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
        return 18;
      },
      _310: o => [o],
      _311: (o0, o1) => [o0, o1],
      _312: (o0, o1, o2) => [o0, o1, o2],
      _313: (o0, o1, o2, o3) => [o0, o1, o2, o3],
      _318: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _324: x0 => new ArrayBuffer(x0),
      _329: x0 => x0.flags,
      _336: (o, p) => o[p],
      _339: x0 => x0.random(),
      _340: (x0,x1) => x0.getRandomValues(x1),
      _341: () => globalThis.crypto,
      _342: () => globalThis.Math,
      _343: Function.prototype.call.bind(Number.prototype.toString),
      _344: Function.prototype.call.bind(BigInt.prototype.toString),
      _345: Function.prototype.call.bind(Number.prototype.toString),
      _2715: x0 => x0.port1,
      _2716: x0 => x0.port2,
      _2719: (x0,x1) => { x0.onmessage = x1 },
      _2721: (x0,x1) => { x0.onmessageerror = x1 },
      _2776: (x0,x1) => { x0.onmessage = x1 },

    };

    const baseImports = {
      dart2wasm: dart2wasm,
      Math: Math,
      Date: Date,
      Object: Object,
      Array: Array,
      Reflect: Reflect,
      S: new Proxy({}, { get(_, prop) { return prop; } }),

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
