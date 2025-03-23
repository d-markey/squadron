
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
  async instantiate(additionalImports, {loadDeferredWasm} = {}) {
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

      throw "Unable to print message: " + js;
    }

    // Converts a Dart List to a JS array. Any Dart objects will be converted, but
    // this will be cheap for JSValues.
    function arrayFromDartList(constructor, list) {
      const exports = dartInstance.exports;
      const read = exports.$listRead;
      const length = exports.$listLength(list);
      const array = new constructor(length);
      for (let i = 0; i < length; i++) {
        array[i] = read(list, i);
      }
      return array;
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

      _80: Date.now,
      _82: s => new Date(s * 1000).getTimezoneOffset() * 60,
      _84: () => {
        let stackString = new Error().stack.toString();
        let frames = stackString.split('\n');
        let drop = 2;
        if (frames[0] === 'Error') {
            drop += 1;
        }
        return frames.slice(drop).join('\n');
      },
      _104: s => JSON.stringify(s),
      _105: s => printToConsole(s),
      _106: a => a.join(''),
      _122: (a, i) => a.push(i),
      _133: a => a.length,
      _135: (a, i) => a[i],
      _136: (a, i, v) => a[i] = v,
      _139: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
      _140: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
      _141: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
      _142: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
      _143: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
      _144: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
      _145: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
      _148: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
      _149: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
      _152: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
      _156: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
      _157: (b, o) => new DataView(b, o),
      _159: Function.prototype.call.bind(DataView.prototype.getUint8),
      _161: Function.prototype.call.bind(DataView.prototype.getInt8),
      _163: Function.prototype.call.bind(DataView.prototype.getUint16),
      _165: Function.prototype.call.bind(DataView.prototype.getInt16),
      _167: Function.prototype.call.bind(DataView.prototype.getUint32),
      _169: Function.prototype.call.bind(DataView.prototype.getInt32),
      _175: Function.prototype.call.bind(DataView.prototype.getFloat32),
      _177: Function.prototype.call.bind(DataView.prototype.getFloat64),
      _195: o => Object.keys(o),
      _200: (c) =>
      queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
      _264: () => globalThis.self,
      _265: (x0,x1) => x0.postMessage(x1),
      _266: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._266(f,arguments.length,x0) }),
      _312: o => o === undefined,
      _331: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
      _333: o => {
        const proto = Object.getPrototypeOf(o);
        return proto === Object.prototype || proto === null;
      },
      _335: (l, r) => l === r,
      _336: o => o,
      _337: o => o,
      _338: o => o,
      _339: b => !!b,
      _340: o => o.length,
      _343: (o, i) => o[i],
      _344: f => f.dartFunction,
      _345: l => arrayFromDartList(Int8Array, l),
      _346: l => arrayFromDartList(Uint8Array, l),
      _347: l => arrayFromDartList(Uint8ClampedArray, l),
      _348: l => arrayFromDartList(Int16Array, l),
      _349: l => arrayFromDartList(Uint16Array, l),
      _350: l => arrayFromDartList(Int32Array, l),
      _351: l => arrayFromDartList(Uint32Array, l),
      _352: l => arrayFromDartList(Float32Array, l),
      _353: l => arrayFromDartList(Float64Array, l),
      _355: (data, length) => {
        const getValue = dartInstance.exports.$byteDataGetUint8;
        const view = new DataView(new ArrayBuffer(length));
        for (let i = 0; i < length; i++) {
          view.setUint8(i, getValue(data, i));
        }
        return view;
      },
      _356: l => arrayFromDartList(Array, l),
      _357: () => ({}),
      _358: () => [],
      _359: l => new Array(l),
      _363: (o, p) => o[p],
      _364: (o, p, v) => o[p] = v,
      _365: (o, m, a) => o[m].apply(o, a),
      _367: o => String(o),
      _369: o => {
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
        return 17;
      },
      _398: x0 => x0.random(),
      _399: x0 => x0.random(),
      _403: () => globalThis.Math,
      _405: Function.prototype.call.bind(Number.prototype.toString),
      _2788: x0 => x0.data,
      _2889: (x0,x1) => x0.onmessage = x1,

    };

    const baseImports = {
      dart2wasm: dart2wasm,


      Math: Math,
      Date: Date,
      Object: Object,
      Array: Array,
      Reflect: Reflect,
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
    };

    const deferredLibraryHelper = {
      "loadModule": async (moduleName) => {
        if (!loadDeferredWasm) {
          throw "No implementation of loadDeferredWasm provided.";
        }
        const source = await Promise.resolve(loadDeferredWasm(moduleName));
        const module = await ((source instanceof Response)
            ? WebAssembly.compileStreaming(source, this.builtins)
            : WebAssembly.compile(source, this.builtins));
        return await WebAssembly.instantiate(module, {
          ...baseImports,
          ...additionalImports,
          "wasm:js-string": jsStringPolyfill,
          "module0": dartInstance.exports,
        });
      },
    };

    dartInstance = await WebAssembly.instantiate(this.module, {
      ...baseImports,
      ...additionalImports,
      "deferredLibraryHelper": deferredLibraryHelper,
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

