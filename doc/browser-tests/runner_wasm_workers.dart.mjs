
// `modulePromise` is a promise to the `WebAssembly.module` object to be
//   instantiated.
// `importObjectPromise` is a promise to an object that contains any additional
//   imports needed by the module that aren't provided by the standard runtime.
//   The fields on this object will be merged into the importObject with which
//   the module will be instantiated.
// This function returns a promise to the instantiated module.
export const instantiate = async (modulePromise, importObjectPromise) => {
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

_12: x0 => new Array(x0),
_15: (o, c) => o instanceof c,
_19: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._19(f,arguments.length,x0) }),
_20: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._20(f,arguments.length,x0) }),
_49: v => v.toString(),
_50: (d, digits) => d.toFixed(digits),
_61: Date.now,
_63: s => new Date(s * 1000).getTimezoneOffset() * 60 ,
_64: s => {
      if (!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(s)) {
        return NaN;
      }
      return parseFloat(s);
    },
_65: () => {
          let stackString = new Error().stack.toString();
          let frames = stackString.split('\n');
          let drop = 2;
          if (frames[0] === 'Error') {
              drop += 1;
          }
          return frames.slice(drop).join('\n');
        },
_66: () => typeof dartUseDateNowForTicks !== "undefined",
_67: () => 1000 * performance.now(),
_68: () => Date.now(),
_69: () => {
      // On browsers return `globalThis.location.href`
      if (globalThis.location != null) {
        return globalThis.location.href;
      }
      return null;
    },
_70: () => {
        return typeof process != "undefined" &&
               Object.prototype.toString.call(process) == "[object process]" &&
               process.platform == "win32"
      },
_85: s => JSON.stringify(s),
_86: s => printToConsole(s),
_87: a => a.join(''),
_88: (o, a, b) => o.replace(a, b),
_90: (s, t) => s.split(t),
_91: s => s.toLowerCase(),
_92: s => s.toUpperCase(),
_93: s => s.trim(),
_95: s => s.trimRight(),
_97: (s, p, i) => s.indexOf(p, i),
_98: (s, p, i) => s.lastIndexOf(p, i),
_99: (s) => s.replace(/\$/g, "$$$$"),
_100: Object.is,
_101: s => s.toUpperCase(),
_102: s => s.toLowerCase(),
_103: (a, i) => a.push(i),
_104: (a, i) => a.splice(i, 1)[0],
_106: (a, l) => a.length = l,
_107: a => a.pop(),
_108: (a, i) => a.splice(i, 1),
_110: (a, s) => a.join(s),
_111: (a, s, e) => a.slice(s, e),
_112: (a, s, e) => a.splice(s, e),
_113: (a, b) => a == b ? 0 : (a > b ? 1 : -1),
_114: a => a.length,
_115: (a, l) => a.length = l,
_116: (a, i) => a[i],
_117: (a, i, v) => a[i] = v,
_119: (o, offsetInBytes, lengthInBytes) => {
      var dst = new ArrayBuffer(lengthInBytes);
      new Uint8Array(dst).set(new Uint8Array(o, offsetInBytes, lengthInBytes));
      return new DataView(dst);
    },
_120: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
_121: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
_122: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
_123: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
_124: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
_125: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
_126: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
_129: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
_130: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
_133: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
_134: o => o.byteLength,
_135: o => o.buffer,
_136: o => o.byteOffset,
_137: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
_138: (b, o) => new DataView(b, o),
_139: (b, o, l) => new DataView(b, o, l),
_140: Function.prototype.call.bind(DataView.prototype.getUint8),
_141: Function.prototype.call.bind(DataView.prototype.setUint8),
_142: Function.prototype.call.bind(DataView.prototype.getInt8),
_143: Function.prototype.call.bind(DataView.prototype.setInt8),
_144: Function.prototype.call.bind(DataView.prototype.getUint16),
_145: Function.prototype.call.bind(DataView.prototype.setUint16),
_146: Function.prototype.call.bind(DataView.prototype.getInt16),
_147: Function.prototype.call.bind(DataView.prototype.setInt16),
_148: Function.prototype.call.bind(DataView.prototype.getUint32),
_149: Function.prototype.call.bind(DataView.prototype.setUint32),
_150: Function.prototype.call.bind(DataView.prototype.getInt32),
_151: Function.prototype.call.bind(DataView.prototype.setInt32),
_152: Function.prototype.call.bind(DataView.prototype.getBigUint64),
_153: Function.prototype.call.bind(DataView.prototype.setBigUint64),
_154: Function.prototype.call.bind(DataView.prototype.getBigInt64),
_155: Function.prototype.call.bind(DataView.prototype.setBigInt64),
_156: Function.prototype.call.bind(DataView.prototype.getFloat32),
_157: Function.prototype.call.bind(DataView.prototype.setFloat32),
_158: Function.prototype.call.bind(DataView.prototype.getFloat64),
_159: Function.prototype.call.bind(DataView.prototype.setFloat64),
_160: (x0,x1) => x0.getRandomValues(x1),
_161: x0 => new Uint8Array(x0),
_162: () => globalThis.crypto,
_165: (x0,x1,x2) => x0.postMessage(x1,x2),
_178: o => Object.keys(o),
_179: (ms, c) =>
              setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
_180: (handle) => clearTimeout(handle),
_181: (ms, c) =>
          setInterval(() => dartInstance.exports.$invokeCallback(c), ms),
_182: (handle) => clearInterval(handle),
_183: (c) =>
              queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
_184: () => Date.now(),
_185: x0 => new Worker(x0),
_186: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._186(f,arguments.length,x0) }),
_187: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._187(f,arguments.length,x0) }),
_188: (x0,x1) => x0.postMessage(x1),
_189: x0 => x0.terminate(),
_190: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._190(f,arguments.length,x0) }),
_191: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._191(f,arguments.length,x0) }),
_192: x0 => x0.terminate(),
_193: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._193(f,arguments.length,x0) }),
_194: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._194(f,arguments.length,x0) }),
_195: x0 => x0.terminate(),
_196: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._196(f,arguments.length,x0) }),
_197: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._197(f,arguments.length,x0) }),
_198: x0 => x0.terminate(),
_199: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._199(f,arguments.length,x0) }),
_200: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._200(f,arguments.length,x0) }),
_201: x0 => x0.terminate(),
_202: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._202(f,arguments.length,x0) }),
_203: x0 => x0.close(),
_204: x0 => x0.close(),
_205: () => new MessageChannel(),
_206: (x0,x1) => x0.error(x1),
_222: (x0,x1) => x0.createElement(x1),
_225: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._225(f,arguments.length,x0) }),
_226: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._226(f,arguments.length,x0) }),
_227: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
_228: (x0,x1,x2,x3) => x0.removeEventListener(x1,x2,x3),
_234: (x0,x1) => x0.log(x1),
_235: (x0,x1) => globalThis.fetch(x0,x1),
_236: () => new MessageChannel(),
_237: (x0,x1) => x0.postMessage(x1),
_238: (x0,x1,x2) => x0.postMessage(x1,x2),
_239: x0 => x0.close(),
_240: x0 => x0.close(),
_241: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._241(f,arguments.length,x0) }),
_242: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._242(f,arguments.length,x0) }),
_243: () => new MessageChannel(),
_244: () => new MessageChannel(),
_245: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._245(f,arguments.length,x0) }),
_246: x0 => x0.close(),
_247: () => new MessageChannel(),
_248: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._248(f,arguments.length,x0) }),
_249: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._249(f,arguments.length,x0) }),
_250: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._250(f,arguments.length,x0) }),
_251: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._251(f,arguments.length,x0) }),
_252: (x0,x1,x2) => x0.postMessage(x1,x2),
_253: x0 => x0.close(),
_254: x0 => x0.close(),
_255: x0 => x0.terminate(),
_256: x0 => globalThis.URL.revokeObjectURL(x0),
_257: x0 => ({type: x0}),
_258: (x0,x1) => new Blob(x0,x1),
_259: x0 => globalThis.URL.createObjectURL(x0),
_260: x0 => x0.terminate(),
_261: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._261(f,arguments.length,x0) }),
_262: (x0,x1) => x0.log(x1),
_263: (x0,x1,x2) => x0.scrollTo(x1,x2),
_264: (x0,x1) => x0.querySelector(x1),
_270: (x0,x1) => x0.appendChild(x1),
_289: (s, m) => {
          try {
            return new RegExp(s, m);
          } catch (e) {
            return String(e);
          }
        },
_290: (x0,x1) => x0.exec(x1),
_291: (x0,x1) => x0.test(x1),
_292: (x0,x1) => x0.exec(x1),
_293: (x0,x1) => x0.exec(x1),
_294: x0 => x0.pop(),
_298: (x0,x1,x2) => x0[x1] = x2,
_300: o => o === undefined,
_301: o => typeof o === 'boolean',
_302: o => typeof o === 'number',
_304: o => typeof o === 'string',
_307: o => o instanceof Int8Array,
_308: o => o instanceof Uint8Array,
_309: o => o instanceof Uint8ClampedArray,
_310: o => o instanceof Int16Array,
_311: o => o instanceof Uint16Array,
_312: o => o instanceof Int32Array,
_313: o => o instanceof Uint32Array,
_314: o => o instanceof Float32Array,
_315: o => o instanceof Float64Array,
_316: o => o instanceof ArrayBuffer,
_317: o => o instanceof DataView,
_318: o => o instanceof Array,
_319: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
_321: o => {
            const proto = Object.getPrototypeOf(o);
            return proto === Object.prototype || proto === null;
          },
_322: o => o instanceof RegExp,
_323: (l, r) => l === r,
_324: o => o,
_325: o => o,
_326: o => o,
_327: b => !!b,
_328: o => o.length,
_331: (o, i) => o[i],
_332: f => f.dartFunction,
_333: l => arrayFromDartList(Int8Array, l),
_334: (data, length) => {
          const jsBytes = new Uint8Array(length);
          const getByte = dartInstance.exports.$uint8ListGet;
          for (let i = 0; i < length; i++) {
            jsBytes[i] = getByte(data, i);
          }
          return jsBytes;
        },
_335: l => arrayFromDartList(Uint8ClampedArray, l),
_336: l => arrayFromDartList(Int16Array, l),
_337: l => arrayFromDartList(Uint16Array, l),
_338: l => arrayFromDartList(Int32Array, l),
_339: l => arrayFromDartList(Uint32Array, l),
_340: l => arrayFromDartList(Float32Array, l),
_341: l => arrayFromDartList(Float64Array, l),
_342: (data, length) => {
          const read = dartInstance.exports.$byteDataGetUint8;
          const view = new DataView(new ArrayBuffer(length));
          for (let i = 0; i < length; i++) {
              view.setUint8(i, read(data, i));
          }
          return view;
        },
_343: l => arrayFromDartList(Array, l),
_344:       (s, length) => {
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
      }
      ,
_345:     (s, length) => {
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
    }
    ,
_346:     (s) => {
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
    }
    ,
_347: () => ({}),
_348: () => [],
_349: l => new Array(l),
_350: () => globalThis,
_352: (o, p) => p in o,
_353: (o, p) => o[p],
_354: (o, p, v) => o[p] = v,
_355: (o, m, a) => o[m].apply(o, a),
_357: o => String(o),
_358: (p, s, f) => p.then(s, f),
_359: s => {
      if (/[[\]{}()*+?.\\^$|]/.test(s)) {
          s = s.replace(/[[\]{}()*+?.\\^$|]/g, '\\$&');
      }
      return s;
    },
_362: x0 => x0.index,
_363: x0 => x0.groups,
_364: x0 => x0.length,
_366: (x0,x1) => x0[x1],
_367: (x0,x1) => x0.exec(x1),
_369: x0 => x0.flags,
_370: x0 => x0.multiline,
_371: x0 => x0.ignoreCase,
_372: x0 => x0.unicode,
_373: x0 => x0.dotAll,
_374: (x0,x1) => x0.lastIndex = x1,
_375: (o, p) => p in o,
_376: (o, p) => o[p],
_630: (x0,x1) => x0.onscroll = x1,
_2249: () => globalThis.window,
_2296: x0 => x0.location,
_2313: x0 => x0.parent,
_2315: x0 => x0.navigator,
_2589: x0 => x0.origin,
_2598: x0 => x0.pathname,
_2639: x0 => x0.message,
_2640: x0 => x0.filename,
_2641: x0 => x0.lineno,
_2706: x0 => x0.userAgent,
_2757: x0 => x0.data,
_2788: x0 => x0.port1,
_2789: x0 => x0.port2,
_2795: (x0,x1) => x0.onmessage = x1,
_2797: (x0,x1) => x0.onmessageerror = x1,
_2870: (x0,x1) => x0.onmessage = x1,
_2872: (x0,x1) => x0.onmessageerror = x1,
_2874: (x0,x1) => x0.onerror = x1,
_5030: () => globalThis.document,
_5482: x0 => x0.scrollTop,
_5487: x0 => x0.scrollHeight,
_5491: x0 => x0.clientHeight,
_5497: (x0,x1) => x0.innerHTML = x1,
_7580: x0 => x0.status,
_7581: x0 => x0.ok,
_11978: () => globalThis.console
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

    dartInstance = await WebAssembly.instantiate(await modulePromise, {
        ...baseImports,
        ...(await importObjectPromise),
        "wasm:js-string": jsStringPolyfill,
    });

    return dartInstance;
}

// Call the main function for the instantiated module
// `moduleInstance` is the instantiated dart2wasm module
// `args` are any arguments that should be passed into the main function.
export const invoke = (moduleInstance, ...args) => {
  moduleInstance.exports.$invokeMain(args);
}

