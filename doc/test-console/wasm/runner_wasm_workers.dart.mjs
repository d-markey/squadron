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
      _7: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._7(f,arguments.length,x0) }),
      _8: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._8(f,arguments.length,x0,x1) }),
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
      _79: () => typeof dartUseDateNowForTicks !== "undefined",
      _80: () => 1000 * performance.now(),
      _81: () => Date.now(),
      _82: () => {
        // On browsers return `globalThis.location.href`
        if (globalThis.location != null) {
          return globalThis.location.href;
        }
        return null;
      },
      _83: () => {
        return typeof process != "undefined" &&
               Object.prototype.toString.call(process) == "[object process]" &&
               process.platform == "win32"
      },
      _99: s => JSON.stringify(s),
      _100: s => printToConsole(s),
      _101: (o, p, r) => o.replaceAll(p, () => r),
      _102: (o, p, r) => o.replace(p, () => r),
      _103: Function.prototype.call.bind(String.prototype.toLowerCase),
      _104: s => s.toUpperCase(),
      _105: s => s.trim(),
      _107: s => s.trimRight(),
      _108: (string, times) => string.repeat(times),
      _109: Function.prototype.call.bind(String.prototype.indexOf),
      _110: (s, p, i) => s.lastIndexOf(p, i),
      _111: (string, token) => string.split(token),
      _112: Object.is,
      _113: o => o instanceof Array,
      _114: (a, i) => a.push(i),
      _115: (a, i) => a.splice(i, 1)[0],
      _117: (a, l) => a.length = l,
      _118: a => a.pop(),
      _119: (a, i) => a.splice(i, 1),
      _120: (a, s) => a.join(s),
      _121: (a, s, e) => a.slice(s, e),
      _122: (a, s, e) => a.splice(s, e),
      _123: (a, b) => a == b ? 0 : (a > b ? 1 : -1),
      _124: a => a.length,
      _125: (a, l) => a.length = l,
      _126: (a, i) => a[i],
      _127: (a, i, v) => a[i] = v,
      _130: (o, offsetInBytes, lengthInBytes) => {
        var dst = new ArrayBuffer(lengthInBytes);
        new Uint8Array(dst).set(new Uint8Array(o, offsetInBytes, lengthInBytes));
        return new DataView(dst);
      },
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
      _181: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._181(f,arguments.length,x0) }),
      _194: (ms, c) =>
      setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
      _195: (handle) => clearTimeout(handle),
      _196: (ms, c) =>
      setInterval(() => dartInstance.exports.$invokeCallback(c), ms),
      _197: (handle) => clearInterval(handle),
      _198: (c) =>
      queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
      _199: () => Date.now(),
      _204: o => Object.keys(o),
      _205: x0 => new Worker(x0),
      _206: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._206(f,arguments.length,x0) }),
      _207: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._207(f,arguments.length,x0) }),
      _208: (x0,x1) => x0.postMessage(x1),
      _209: x0 => x0.terminate(),
      _210: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._210(f,arguments.length,x0) }),
      _211: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._211(f,arguments.length,x0) }),
      _212: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._212(f,arguments.length,x0) }),
      _213: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._213(f,arguments.length,x0) }),
      _214: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._214(f,arguments.length,x0) }),
      _215: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._215(f,arguments.length,x0) }),
      _216: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._216(f,arguments.length,x0) }),
      _217: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._217(f,arguments.length,x0) }),
      _218: x0 => x0.getTime(),
      _219: x0 => globalThis.BigInt(x0),
      _220: (x0,x1) => x0.at(x1),
      _221: () => new MessageChannel(),
      _222: (x0,x1) => globalThis.Object.is(x0,x1),
      _223: () => new Set(),
      _224: (x0,x1) => x0.add(x1),
      _225: () => new Map(),
      _226: (x0,x1,x2) => x0.set(x1,x2),
      _227: (x0,x1) => x0.push(x1),
      _228: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._228(f,arguments.length,x0) }),
      _229: x0 => x0.close(),
      _230: (x0,x1) => x0.error(x1),
      _243: (x0,x1) => x0.createElement(x1),
      _245: (x0,x1) => x0.querySelector(x1),
      _246: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._246(f,arguments.length,x0) }),
      _247: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._247(f,arguments.length,x0) }),
      _248: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
      _249: (x0,x1,x2,x3) => x0.removeEventListener(x1,x2,x3),
      _256: (x0,x1) => globalThis.fetch(x0,x1),
      _257: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._257(f,arguments.length,x0) }),
      _258: (x0,x1,x2) => x0.postMessage(x1,x2),
      _259: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._259(f,arguments.length,x0) }),
      _260: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._260(f,arguments.length,x0) }),
      _261: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._261(f,arguments.length,x0) }),
      _262: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._262(f,arguments.length,x0) }),
      _263: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._263(f,arguments.length,x0) }),
      _264: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._264(f,arguments.length,x0) }),
      _265: (x0,x1,x2) => x0.postMessage(x1,x2),
      _266: (x0,x1) => x0.postMessage(x1),
      _267: x0 => globalThis.URL.revokeObjectURL(x0),
      _268: x0 => ({type: x0}),
      _269: (x0,x1) => new Blob(x0,x1),
      _270: x0 => globalThis.URL.createObjectURL(x0),
      _271: x0 => x0.entries(),
      _272: x0 => x0.values(),
      _273: x0 => x0.toString(),
      _274: x0 => x0.length,
      _275: x0 => x0.byteLength,
      _276: x0 => x0.buffer,
      _277: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._277(f,arguments.length,x0) }),
      _278: (x0,x1) => x0.remove(x1),
      _279: (x0,x1) => x0.add(x1),
      _280: x0 => x0.scrollIntoView(),
      _281: (x0,x1) => x0.appendChild(x1),
      _282: (x0,x1,x2) => x0.scrollTo(x1,x2),
      _283: (x0,x1) => x0.getElementsByClassName(x1),
      _284: (x0,x1) => x0.item(x1),
      _286: (x0,x1,x2) => x0.postMessage(x1,x2),
      _298: (s, m) => {
        try {
          return new RegExp(s, m);
        } catch (e) {
          return String(e);
        }
      },
      _299: (x0,x1) => x0.exec(x1),
      _300: (x0,x1) => x0.test(x1),
      _301: x0 => x0.pop(),
      _303: o => o === undefined,
      _305: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
      _307: o => {
        const proto = Object.getPrototypeOf(o);
        return proto === Object.prototype || proto === null;
      },
      _308: o => o instanceof RegExp,
      _309: (l, r) => l === r,
      _310: o => o,
      _311: o => o,
      _312: o => o,
      _313: b => !!b,
      _314: o => o.length,
      _316: (o, i) => o[i],
      _317: f => f.dartFunction,
      _318: () => ({}),
      _319: () => [],
      _321: () => globalThis,
      _322: (constructor, args) => {
        const factoryFunction = constructor.bind.apply(
            constructor, [null, ...args]);
        return new factoryFunction();
      },
      _323: (o, p) => p in o,
      _324: (o, p) => o[p],
      _325: (o, p, v) => o[p] = v,
      _326: (o, m, a) => o[m].apply(o, a),
      _328: o => String(o),
      _329: (p, s, f) => p.then(s, (e) => f(e, e === undefined)),
      _330: o => {
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
      _331: o => [o],
      _332: (o0, o1) => [o0, o1],
      _333: (o0, o1, o2) => [o0, o1, o2],
      _334: (o0, o1, o2, o3) => [o0, o1, o2, o3],
      _335: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI8ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _337: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI16ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _339: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _341: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _345: x0 => new ArrayBuffer(x0),
      _346: s => {
        if (/[[\]{}()*+?.\\^$|]/.test(s)) {
            s = s.replace(/[[\]{}()*+?.\\^$|]/g, '\\$&');
        }
        return s;
      },
      _348: x0 => x0.index,
      _349: x0 => x0.groups,
      _350: x0 => x0.flags,
      _351: x0 => x0.multiline,
      _352: x0 => x0.ignoreCase,
      _353: x0 => x0.unicode,
      _354: x0 => x0.dotAll,
      _355: (x0,x1) => { x0.lastIndex = x1 },
      _357: (o, p) => o[p],
      _358: (o, p, v) => o[p] = v,
      _360: x0 => x0.random(),
      _361: (x0,x1) => x0.getRandomValues(x1),
      _362: () => globalThis.crypto,
      _363: () => globalThis.Math,
      _364: Function.prototype.call.bind(Number.prototype.toString),
      _365: Function.prototype.call.bind(BigInt.prototype.toString),
      _366: Function.prototype.call.bind(Number.prototype.toString),
      _486: x0 => x0.innerText,
      _610: (x0,x1) => { x0.onscroll = x1 },
      _2203: () => globalThis.window,
      _2247: x0 => x0.location,
      _2264: x0 => x0.parent,
      _2266: x0 => x0.navigator,
      _2540: x0 => x0.origin,
      _2549: x0 => x0.pathname,
      _2589: x0 => x0.message,
      _2590: x0 => x0.filename,
      _2591: x0 => x0.lineno,
      _2655: x0 => x0.userAgent,
      _2706: x0 => x0.data,
      _2736: x0 => x0.port1,
      _2737: x0 => x0.port2,
      _2740: (x0,x1) => { x0.onmessage = x1 },
      _2742: (x0,x1) => { x0.onmessageerror = x1 },
      _2808: (x0,x1) => { x0.onmessage = x1 },
      _2810: (x0,x1) => { x0.onmessageerror = x1 },
      _2812: (x0,x1) => { x0.onerror = x1 },
      _4816: x0 => x0.length,
      _4864: x0 => x0.parentElement,
      _4877: () => globalThis.document,
      _5297: x0 => x0.classList,
      _5303: x0 => x0.scrollTop,
      _5308: x0 => x0.scrollHeight,
      _5312: x0 => x0.clientHeight,
      _5318: (x0,x1) => { x0.innerHTML = x1 },
      _7345: x0 => x0.status,
      _7346: x0 => x0.ok,
      _11694: () => globalThis.console,

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
