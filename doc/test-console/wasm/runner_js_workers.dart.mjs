// Returns whether the `js-string` built-in is supported.
function detectJsStringBuiltins() {
  let bytes = [
    0,   97,  115, 109, 1,   0,   0,  0,   1,   4,   1,   96,  0,
    0,   2,   23,  1,   14,  119, 97, 115, 109, 58,  106, 115, 45,
    115, 116, 114, 105, 110, 103, 4,  99,  97,  115, 116, 0,   0
  ];
  return WebAssembly.validate(
    new Uint8Array(bytes), {builtins: ['js-string']});
}

// Compiles a dart2wasm-generated main module from `source` which can then
// instantiatable via the `instantiate` method.
//
// `source` needs to be a `Response` object (or promise thereof) e.g. created
// via the `fetch()` JS API.
export async function compileStreaming(source) {
  const builtins = detectJsStringBuiltins()
      ? {builtins: ['js-string']} : {};
  return new CompiledApp(
      await WebAssembly.compileStreaming(source, builtins), builtins);
}

// Compiles a dart2wasm-generated wasm modules from `bytes` which is then
// instantiatable via the `instantiate` method.
export async function compile(bytes) {
  const builtins = detectJsStringBuiltins()
      ? {builtins: ['js-string']} : {};
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

      _10: () => new Array(),
      _11: x0 => new Array(x0),
      _13: x0 => x0.length,
      _15: (x0,x1) => x0[x1],
      _16: (x0,x1,x2) => x0[x1] = x2,
      _19: (x0,x1,x2) => new DataView(x0,x1,x2),
      _21: x0 => new Int8Array(x0),
      _22: (x0,x1,x2) => new Uint8Array(x0,x1,x2),
      _23: x0 => new Uint8Array(x0),
      _25: x0 => new Uint8ClampedArray(x0),
      _27: x0 => new Int16Array(x0),
      _29: x0 => new Uint16Array(x0),
      _31: x0 => new Int32Array(x0),
      _33: x0 => new Uint32Array(x0),
      _35: x0 => new Float32Array(x0),
      _37: x0 => new Float64Array(x0),
      _38: (o, t) => typeof o === t,
      _39: (o, c) => o instanceof c,
      _43: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._43(f,arguments.length,x0) }),
      _44: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._44(f,arguments.length,x0) }),
      _67: (o) => !!o,
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
      _85: () => typeof dartUseDateNowForTicks !== "undefined",
      _86: () => 1000 * performance.now(),
      _87: () => Date.now(),
      _88: () => {
        // On browsers return `globalThis.location.href`
        if (globalThis.location != null) {
          return globalThis.location.href;
        }
        return null;
      },
      _89: () => {
        return typeof process != "undefined" &&
               Object.prototype.toString.call(process) == "[object process]" &&
               process.platform == "win32"
      },
      _103: s => JSON.stringify(s),
      _104: s => printToConsole(s),
      _105: a => a.join(''),
      _106: (o, a, b) => o.replace(a, b),
      _108: (s, t) => s.split(t),
      _109: s => s.toLowerCase(),
      _110: s => s.toUpperCase(),
      _111: s => s.trim(),
      _113: s => s.trimRight(),
      _115: (s, p, i) => s.indexOf(p, i),
      _116: (s, p, i) => s.lastIndexOf(p, i),
      _117: (s) => s.replace(/\$/g, "$$$$"),
      _118: Object.is,
      _119: s => s.toUpperCase(),
      _120: s => s.toLowerCase(),
      _121: (a, i) => a.push(i),
      _122: (a, i) => a.splice(i, 1)[0],
      _124: (a, l) => a.length = l,
      _125: a => a.pop(),
      _126: (a, i) => a.splice(i, 1),
      _128: (a, s) => a.join(s),
      _129: (a, s, e) => a.slice(s, e),
      _130: (a, s, e) => a.splice(s, e),
      _131: (a, b) => a == b ? 0 : (a > b ? 1 : -1),
      _132: a => a.length,
      _133: (a, l) => a.length = l,
      _134: (a, i) => a[i],
      _135: (a, i, v) => a[i] = v,
      _137: (o, offsetInBytes, lengthInBytes) => {
        var dst = new ArrayBuffer(lengthInBytes);
        new Uint8Array(dst).set(new Uint8Array(o, offsetInBytes, lengthInBytes));
        return new DataView(dst);
      },
      _138: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
      _139: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
      _140: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
      _141: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
      _142: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
      _143: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
      _144: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
      _147: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
      _148: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
      _150: l => new DataView(new ArrayBuffer(l)),
      _151: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
      _152: o => o.byteLength,
      _153: o => o.buffer,
      _154: o => o.byteOffset,
      _155: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
      _156: (b, o) => new DataView(b, o),
      _157: (b, o, l) => new DataView(b, o, l),
      _158: Function.prototype.call.bind(DataView.prototype.getUint8),
      _159: Function.prototype.call.bind(DataView.prototype.setUint8),
      _160: Function.prototype.call.bind(DataView.prototype.getInt8),
      _161: Function.prototype.call.bind(DataView.prototype.setInt8),
      _162: Function.prototype.call.bind(DataView.prototype.getUint16),
      _163: Function.prototype.call.bind(DataView.prototype.setUint16),
      _164: Function.prototype.call.bind(DataView.prototype.getInt16),
      _165: Function.prototype.call.bind(DataView.prototype.setInt16),
      _166: Function.prototype.call.bind(DataView.prototype.getUint32),
      _167: Function.prototype.call.bind(DataView.prototype.setUint32),
      _168: Function.prototype.call.bind(DataView.prototype.getInt32),
      _169: Function.prototype.call.bind(DataView.prototype.setInt32),
      _170: Function.prototype.call.bind(DataView.prototype.getBigUint64),
      _171: Function.prototype.call.bind(DataView.prototype.setBigUint64),
      _172: Function.prototype.call.bind(DataView.prototype.getBigInt64),
      _173: Function.prototype.call.bind(DataView.prototype.setBigInt64),
      _174: Function.prototype.call.bind(DataView.prototype.getFloat32),
      _175: Function.prototype.call.bind(DataView.prototype.setFloat32),
      _176: Function.prototype.call.bind(DataView.prototype.getFloat64),
      _177: Function.prototype.call.bind(DataView.prototype.setFloat64),
      _178: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._178(f,arguments.length,x0) }),
      _195: o => Object.keys(o),
      _196: (ms, c) =>
      setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
      _197: (handle) => clearTimeout(handle),
      _198: (ms, c) =>
      setInterval(() => dartInstance.exports.$invokeCallback(c), ms),
      _199: (handle) => clearInterval(handle),
      _200: (c) =>
      queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
      _201: () => Date.now(),
      _202: x0 => new Worker(x0),
      _203: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._203(f,arguments.length,x0) }),
      _204: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._204(f,arguments.length,x0) }),
      _205: (x0,x1) => x0.postMessage(x1),
      _206: x0 => x0.terminate(),
      _207: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._207(f,arguments.length,x0) }),
      _208: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._208(f,arguments.length,x0) }),
      _209: x0 => x0.terminate(),
      _210: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._210(f,arguments.length,x0) }),
      _211: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._211(f,arguments.length,x0) }),
      _212: x0 => x0.terminate(),
      _213: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._213(f,arguments.length,x0) }),
      _214: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._214(f,arguments.length,x0) }),
      _215: x0 => x0.terminate(),
      _216: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._216(f,arguments.length,x0) }),
      _217: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._217(f,arguments.length,x0) }),
      _218: x0 => x0.terminate(),
      _219: (x0,x1) => x0.at(x1),
      _220: (x0,x1) => x0.at(x1),
      _221: () => new MessageChannel(),
      _222: (x0,x1) => x0.at(x1),
      _223: () => new MessageChannel(),
      _224: (x0,x1) => x0.at(x1),
      _225: (x0,x1) => x0.at(x1),
      _226: (x0,x1) => x0.at(x1),
      _227: (x0,x1) => x0.at(x1),
      _228: (x0,x1) => x0.at(x1),
      _229: (x0,x1) => x0.at(x1),
      _230: () => new MessageChannel(),
      _231: (x0,x1) => x0.at(x1),
      _232: (x0,x1) => x0.at(x1),
      _233: (x0,x1) => x0.at(x1),
      _234: (x0,x1) => x0.at(x1),
      _235: (x0,x1) => x0.at(x1),
      _236: (x0,x1) => x0.at(x1),
      _237: (x0,x1) => globalThis.Object.is(x0,x1),
      _238: (x0,x1) => x0.at(x1),
      _239: (x0,x1) => x0.at(x1),
      _240: (x0,x1) => globalThis.Object.is(x0,x1),
      _241: (x0,x1) => x0.at(x1),
      _242: (x0,x1) => x0.at(x1),
      _243: (x0,x1) => x0.at(x1),
      _244: () => new MessageChannel(),
      _245: (x0,x1) => x0.at(x1),
      _246: (x0,x1) => x0.at(x1),
      _247: (x0,x1) => x0.at(x1),
      _248: (x0,x1) => x0.at(x1),
      _249: (x0,x1) => x0.at(x1),
      _250: (x0,x1) => x0.at(x1),
      _251: (x0,x1) => x0.at(x1),
      _252: (x0,x1) => globalThis.Object.is(x0,x1),
      _253: (x0,x1) => x0.at(x1),
      _254: (x0,x1) => x0.at(x1),
      _255: (x0,x1) => globalThis.Object.is(x0,x1),
      _256: (x0,x1) => x0.at(x1),
      _257: (x0,x1) => globalThis.Object.is(x0,x1),
      _258: (x0,x1) => x0.at(x1),
      _259: (x0,x1) => x0.at(x1),
      _260: (x0,x1) => x0.at(x1),
      _261: x0 => globalThis.BigInt(x0),
      _262: () => new Set(),
      _263: (x0,x1) => x0.add(x1),
      _264: (x0,x1) => x0.add(x1),
      _265: (x0,x1) => x0.add(x1),
      _266: (x0,x1) => x0.add(x1),
      _267: () => new Map(),
      _268: (x0,x1,x2) => x0.set(x1,x2),
      _269: (x0,x1,x2) => x0.set(x1,x2),
      _270: () => new MessageChannel(),
      _271: () => new MessageChannel(),
      _272: () => new MessageChannel(),
      _273: () => new MessageChannel(),
      _274: (x0,x1) => x0.push(x1),
      _275: x0 => globalThis.BigInt(x0),
      _276: (x0,x1) => x0.push(x1),
      _277: (x0,x1) => x0.push(x1),
      _278: () => new Map(),
      _279: (x0,x1,x2) => x0.set(x1,x2),
      _280: (x0,x1,x2) => x0.set(x1,x2),
      _281: (x0,x1) => x0.at(x1),
      _282: (x0,x1) => x0.at(x1),
      _283: (x0,x1) => x0.at(x1),
      _284: (x0,x1) => x0.at(x1),
      _285: (x0,x1) => x0.at(x1),
      _286: (x0,x1) => x0.at(x1),
      _287: (x0,x1) => x0.at(x1),
      _288: (x0,x1) => x0.at(x1),
      _289: (x0,x1) => x0.at(x1),
      _290: (x0,x1) => x0.at(x1),
      _291: (x0,x1) => globalThis.Object.is(x0,x1),
      _292: (x0,x1) => x0.at(x1),
      _293: (x0,x1) => x0.at(x1),
      _294: (x0,x1) => x0.at(x1),
      _295: (x0,x1) => globalThis.Object.is(x0,x1),
      _296: (x0,x1) => x0.at(x1),
      _297: (x0,x1) => x0.at(x1),
      _298: () => new MessageChannel(),
      _299: () => new MessageChannel(),
      _300: (x0,x1) => x0.at(x1),
      _301: (x0,x1) => x0.at(x1),
      _302: (x0,x1) => x0.at(x1),
      _303: (x0,x1) => x0.at(x1),
      _304: (x0,x1) => globalThis.Object.is(x0,x1),
      _305: () => new MessageChannel(),
      _306: (x0,x1) => x0.at(x1),
      _307: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._307(f,arguments.length,x0) }),
      _308: x0 => x0.close(),
      _309: x0 => x0.close(),
      _310: () => new MessageChannel(),
      _311: (x0,x1) => x0.error(x1),
      _327: (x0,x1) => x0.createElement(x1),
      _330: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._330(f,arguments.length,x0) }),
      _331: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._331(f,arguments.length,x0) }),
      _332: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
      _333: (x0,x1,x2,x3) => x0.removeEventListener(x1,x2,x3),
      _340: (x0,x1) => globalThis.fetch(x0,x1),
      _341: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._341(f,arguments.length,x0) }),
      _342: (x0,x1,x2) => x0.postMessage(x1,x2),
      _343: x0 => x0.close(),
      _344: () => new MessageChannel(),
      _345: (x0,x1) => x0.push(x1),
      _346: x0 => x0.close(),
      _347: x0 => x0.close(),
      _348: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._348(f,arguments.length,x0) }),
      _349: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._349(f,arguments.length,x0) }),
      _350: x0 => x0.close(),
      _351: x0 => x0.close(),
      _352: () => new MessageChannel(),
      _353: () => new MessageChannel(),
      _354: () => new MessageChannel(),
      _355: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._355(f,arguments.length,x0) }),
      _356: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._356(f,arguments.length,x0) }),
      _357: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._357(f,arguments.length,x0) }),
      _358: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._358(f,arguments.length,x0) }),
      _359: (x0,x1,x2) => x0.postMessage(x1,x2),
      _360: x0 => x0.close(),
      _361: x0 => x0.close(),
      _362: x0 => x0.terminate(),
      _363: x0 => x0.terminate(),
      _364: (x0,x1) => x0.postMessage(x1),
      _365: x0 => globalThis.URL.revokeObjectURL(x0),
      _366: x0 => ({type: x0}),
      _367: (x0,x1) => new Blob(x0,x1),
      _368: x0 => globalThis.URL.createObjectURL(x0),
      _369: (x0,x1) => globalThis.Object.is(x0,x1),
      _370: (x0,x1) => globalThis.Object.is(x0,x1),
      _371: (x0,x1) => x0.push(x1),
      _372: (x0,x1) => x0.at(x1),
      _373: x0 => x0.entries(),
      _374: (x0,x1) => x0.at(x1),
      _375: (x0,x1) => x0.at(x1),
      _376: x0 => x0.values(),
      _377: (x0,x1) => x0.push(x1),
      _378: (x0,x1) => x0.push(x1),
      _379: (x0,x1) => x0.push(x1),
      _380: () => new Map(),
      _381: (x0,x1,x2) => x0.set(x1,x2),
      _382: () => new Set(),
      _383: (x0,x1) => x0.add(x1),
      _384: x0 => globalThis.BigInt(x0),
      _385: (x0,x1) => x0.at(x1),
      _386: x0 => x0.entries(),
      _387: (x0,x1) => x0.at(x1),
      _388: (x0,x1) => x0.at(x1),
      _389: x0 => x0.values(),
      _390: x0 => x0.toString(),
      _395: x0 => x0.length,
      _396: x0 => x0.byteLength,
      _406: x0 => x0.buffer,
      _407: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._407(f,arguments.length,x0) }),
      _408: (x0,x1) => x0.remove(x1),
      _409: (x0,x1) => x0.add(x1),
      _410: x0 => x0.scrollIntoView(),
      _411: (x0,x1) => x0.getElementsByClassName(x1),
      _412: (x0,x1,x2) => x0.scrollTo(x1,x2),
      _413: (x0,x1) => x0.item(x1),
      _414: (x0,x1) => x0.querySelector(x1),
      _416: (x0,x1) => x0.appendChild(x1),
      _420: (x0,x1,x2) => x0.postMessage(x1,x2),
      _436: (s, m) => {
        try {
          return new RegExp(s, m);
        } catch (e) {
          return String(e);
        }
      },
      _437: (x0,x1) => x0.exec(x1),
      _438: (x0,x1) => x0.test(x1),
      _439: (x0,x1) => x0.exec(x1),
      _440: (x0,x1) => x0.exec(x1),
      _441: x0 => x0.pop(),
      _443: o => o === undefined,
      _462: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
      _464: o => {
        const proto = Object.getPrototypeOf(o);
        return proto === Object.prototype || proto === null;
      },
      _465: o => o instanceof RegExp,
      _466: (l, r) => l === r,
      _467: o => o,
      _468: o => o,
      _469: o => o,
      _470: b => !!b,
      _471: o => o.length,
      _474: (o, i) => o[i],
      _475: f => f.dartFunction,
      _476: l => arrayFromDartList(Int8Array, l),
      _477: l => arrayFromDartList(Uint8Array, l),
      _478: l => arrayFromDartList(Uint8ClampedArray, l),
      _479: l => arrayFromDartList(Int16Array, l),
      _480: l => arrayFromDartList(Uint16Array, l),
      _481: l => arrayFromDartList(Int32Array, l),
      _482: l => arrayFromDartList(Uint32Array, l),
      _483: l => arrayFromDartList(Float32Array, l),
      _484: l => arrayFromDartList(Float64Array, l),
      _485: x0 => new ArrayBuffer(x0),
      _486: (data, length) => {
        const getValue = dartInstance.exports.$byteDataGetUint8;
        const view = new DataView(new ArrayBuffer(length));
        for (let i = 0; i < length; i++) {
          view.setUint8(i, getValue(data, i));
        }
        return view;
      },
      _487: l => arrayFromDartList(Array, l),
      _488: (s, length) => {
        if (length == 0) return '';
      
        const read = dartInstance.exports.$stringRead1;
        let result = '';
        let index = 0;
        const chunkLength = Math.min(length - index, 500);
        let array = new Array(chunkLength);
        while (index < length) {
          const newChunkLength = Math.min(length - index, 500);
          for (let i = 0; i < newChunkLength; i++) {
            array[i] = read(s, index++);
          }
          if (newChunkLength < chunkLength) {
            array = array.slice(0, newChunkLength);
          }
          result += String.fromCharCode(...array);
        }
        return result;
      },
      _489: (s, length) => {
        if (length == 0) return '';
      
        const read = dartInstance.exports.$stringRead2;
        let result = '';
        let index = 0;
        const chunkLength = Math.min(length - index, 500);
        let array = new Array(chunkLength);
        while (index < length) {
          const newChunkLength = Math.min(length - index, 500);
          for (let i = 0; i < newChunkLength; i++) {
            array[i] = read(s, index++);
          }
          if (newChunkLength < chunkLength) {
            array = array.slice(0, newChunkLength);
          }
          result += String.fromCharCode(...array);
        }
        return result;
      },
      _490: (s) => {
        let length = s.length;
        let range = 0;
        for (let i = 0; i < length; i++) {
          range |= s.codePointAt(i);
        }
        const exports = dartInstance.exports;
        if (range < 256) {
          if (length <= 10) {
            if (length == 1) {
              return exports.$stringAllocate1_1(s.codePointAt(0));
            }
            if (length == 2) {
              return exports.$stringAllocate1_2(s.codePointAt(0), s.codePointAt(1));
            }
            if (length == 3) {
              return exports.$stringAllocate1_3(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2));
            }
            if (length == 4) {
              return exports.$stringAllocate1_4(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2), s.codePointAt(3));
            }
            if (length == 5) {
              return exports.$stringAllocate1_5(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2), s.codePointAt(3), s.codePointAt(4));
            }
            if (length == 6) {
              return exports.$stringAllocate1_6(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2), s.codePointAt(3), s.codePointAt(4), s.codePointAt(5));
            }
            if (length == 7) {
              return exports.$stringAllocate1_7(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2), s.codePointAt(3), s.codePointAt(4), s.codePointAt(5), s.codePointAt(6));
            }
            if (length == 8) {
              return exports.$stringAllocate1_8(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2), s.codePointAt(3), s.codePointAt(4), s.codePointAt(5), s.codePointAt(6), s.codePointAt(7));
            }
            if (length == 9) {
              return exports.$stringAllocate1_9(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2), s.codePointAt(3), s.codePointAt(4), s.codePointAt(5), s.codePointAt(6), s.codePointAt(7), s.codePointAt(8));
            }
            if (length == 10) {
              return exports.$stringAllocate1_10(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2), s.codePointAt(3), s.codePointAt(4), s.codePointAt(5), s.codePointAt(6), s.codePointAt(7), s.codePointAt(8), s.codePointAt(9));
            }
          }
          const dartString = exports.$stringAllocate1(length);
          const write = exports.$stringWrite1;
          for (let i = 0; i < length; i++) {
            write(dartString, i, s.codePointAt(i));
          }
          return dartString;
        } else {
          const dartString = exports.$stringAllocate2(length);
          const write = exports.$stringWrite2;
          for (let i = 0; i < length; i++) {
            write(dartString, i, s.charCodeAt(i));
          }
          return dartString;
        }
      },
      _491: () => ({}),
      _492: () => [],
      _493: l => new Array(l),
      _494: () => globalThis,
      _496: (o, p) => p in o,
      _497: (o, p) => o[p],
      _498: (o, p, v) => o[p] = v,
      _499: (o, m, a) => o[m].apply(o, a),
      _501: o => String(o),
      _502: (p, s, f) => p.then(s, f),
      _503: o => {
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
      _504: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI8ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _506: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI16ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _508: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _510: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _512: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF64ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _514: s => {
        if (/[[\]{}()*+?.\\^$|]/.test(s)) {
            s = s.replace(/[[\]{}()*+?.\\^$|]/g, '\\$&');
        }
        return s;
      },
      _517: x0 => x0.index,
      _518: x0 => x0.groups,
      _521: (x0,x1) => x0.exec(x1),
      _523: x0 => x0.flags,
      _524: x0 => x0.multiline,
      _525: x0 => x0.ignoreCase,
      _526: x0 => x0.unicode,
      _527: x0 => x0.dotAll,
      _528: (x0,x1) => x0.lastIndex = x1,
      _530: (o, p) => o[p],
      _531: (o, p, v) => o[p] = v,
      _533: v => v.toString(),
      _534: (d, digits) => d.toFixed(digits),
      _538: x0 => x0.random(),
      _539: x0 => x0.random(),
      _540: (x0,x1) => x0.getRandomValues(x1),
      _541: () => globalThis.crypto,
      _543: () => globalThis.Math,
      _672: x0 => x0.innerText,
      _796: (x0,x1) => x0.onscroll = x1,
      _2415: () => globalThis.window,
      _2462: x0 => x0.location,
      _2479: x0 => x0.parent,
      _2481: x0 => x0.navigator,
      _2755: x0 => x0.origin,
      _2764: x0 => x0.pathname,
      _2805: x0 => x0.message,
      _2806: x0 => x0.filename,
      _2807: x0 => x0.lineno,
      _2872: x0 => x0.userAgent,
      _2923: x0 => x0.data,
      _2954: x0 => x0.port1,
      _2955: x0 => x0.port2,
      _2961: (x0,x1) => x0.onmessage = x1,
      _2963: (x0,x1) => x0.onmessageerror = x1,
      _3035: (x0,x1) => x0.onmessage = x1,
      _3037: (x0,x1) => x0.onmessageerror = x1,
      _3039: (x0,x1) => x0.onerror = x1,
      _5129: x0 => x0.length,
      _5195: () => globalThis.document,
      _5641: x0 => x0.classList,
      _5647: x0 => x0.scrollTop,
      _5652: x0 => x0.scrollHeight,
      _5656: x0 => x0.clientHeight,
      _5662: (x0,x1) => x0.innerHTML = x1,
      _7745: x0 => x0.status,
      _7746: x0 => x0.ok,
      _12143: () => globalThis.console,

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

