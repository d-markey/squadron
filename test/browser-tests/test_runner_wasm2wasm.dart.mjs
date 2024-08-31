
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
_61: Date.now,
_63: s => new Date(s * 1000).getTimezoneOffset() * 60 ,
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
_106: (a, l) => a.length = l,
_110: (a, s) => a.join(s),
_113: (a, b) => a == b ? 0 : (a > b ? 1 : -1),
_114: a => a.length,
_116: (a, i) => a[i],
_117: (a, i, v) => a[i] = v,
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
_135: o => o.buffer,
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
_156: Function.prototype.call.bind(DataView.prototype.getFloat32),
_157: Function.prototype.call.bind(DataView.prototype.setFloat32),
_158: Function.prototype.call.bind(DataView.prototype.getFloat64),
_159: Function.prototype.call.bind(DataView.prototype.setFloat64),
_160: (x0,x1) => x0.getRandomValues(x1),
_161: x0 => new Uint8Array(x0),
_162: () => globalThis.crypto,
_165: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._165(f,arguments.length,x0) }),
_166: x0 => x0.close(),
_167: x0 => x0.close(),
_168: () => new MessageChannel(),
_169: (x0,x1,x2) => x0.postMessage(x1,x2),
_171: x0 => globalThis.dartPrint = x0,
_172: (x0,x1) => x0.querySelector(x1),
_173: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._173(f,arguments.length,x0) }),
_174: x0 => new Worker(x0),
_175: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._175(f,arguments.length,x0) }),
_176: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._176(f,arguments.length,x0) }),
_177: (x0,x1) => x0.postMessage(x1),
_178: x0 => x0.terminate(),
_179: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._179(f,arguments.length,x0) }),
_180: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._180(f,arguments.length,x0) }),
_181: x0 => x0.terminate(),
_182: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._182(f,arguments.length,x0) }),
_183: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._183(f,arguments.length,x0) }),
_184: x0 => x0.terminate(),
_185: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._185(f,arguments.length,x0) }),
_186: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._186(f,arguments.length,x0) }),
_187: x0 => x0.terminate(),
_188: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._188(f,arguments.length,x0) }),
_189: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._189(f,arguments.length,x0) }),
_190: x0 => x0.terminate(),
_204: () => new MessageChannel(),
_205: (x0,x1) => x0.postMessage(x1),
_206: (x0,x1,x2) => x0.postMessage(x1,x2),
_207: x0 => x0.close(),
_208: x0 => x0.close(),
_209: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._209(f,arguments.length,x0) }),
_210: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._210(f,arguments.length,x0) }),
_211: () => new MessageChannel(),
_212: () => new MessageChannel(),
_213: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._213(f,arguments.length,x0) }),
_214: x0 => x0.close(),
_215: () => new MessageChannel(),
_216: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._216(f,arguments.length,x0) }),
_217: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._217(f,arguments.length,x0) }),
_218: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._218(f,arguments.length,x0) }),
_219: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._219(f,arguments.length,x0) }),
_220: (x0,x1,x2) => x0.postMessage(x1,x2),
_221: x0 => x0.close(),
_222: x0 => x0.close(),
_223: x0 => x0.terminate(),
_236: o => Object.keys(o),
_237: (ms, c) =>
              setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
_238: (handle) => clearTimeout(handle),
_239: (ms, c) =>
          setInterval(() => dartInstance.exports.$invokeCallback(c), ms),
_240: (handle) => clearInterval(handle),
_241: (c) =>
              queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
_242: () => Date.now(),
_243: x0 => ({type: x0}),
_244: (x0,x1) => new Blob(x0,x1),
_245: x0 => globalThis.URL.createObjectURL(x0),
_252: (x0,x1) => x0.createElement(x1),
_255: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._255(f,arguments.length,x0) }),
_256: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._256(f,arguments.length,x0) }),
_257: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
_258: (x0,x1,x2,x3) => x0.removeEventListener(x1,x2,x3),
_264: (x0,x1) => globalThis.fetch(x0,x1),
_277: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._277(f,arguments.length,x0) }),
_278: (x0,x1) => x0.log(x1),
_281: (x0,x1) => x0.appendChild(x1),
_282: (x0,x1,x2) => x0.scrollTo(x1,x2),
_284: (s, m) => {
          try {
            return new RegExp(s, m);
          } catch (e) {
            return String(e);
          }
        },
_285: (x0,x1) => x0.exec(x1),
_286: (x0,x1) => x0.test(x1),
_287: (x0,x1) => x0.exec(x1),
_288: (x0,x1) => x0.exec(x1),
_289: x0 => x0.pop(),
_293: (x0,x1,x2) => x0[x1] = x2,
_295: o => o === undefined,
_296: o => typeof o === 'boolean',
_297: o => typeof o === 'number',
_299: o => typeof o === 'string',
_302: o => o instanceof Int8Array,
_303: o => o instanceof Uint8Array,
_304: o => o instanceof Uint8ClampedArray,
_305: o => o instanceof Int16Array,
_306: o => o instanceof Uint16Array,
_307: o => o instanceof Int32Array,
_308: o => o instanceof Uint32Array,
_309: o => o instanceof Float32Array,
_310: o => o instanceof Float64Array,
_311: o => o instanceof ArrayBuffer,
_312: o => o instanceof DataView,
_313: o => o instanceof Array,
_314: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
_316: o => {
            const proto = Object.getPrototypeOf(o);
            return proto === Object.prototype || proto === null;
          },
_317: o => o instanceof RegExp,
_318: (l, r) => l === r,
_319: o => o,
_320: o => o,
_321: o => o,
_322: b => !!b,
_323: o => o.length,
_326: (o, i) => o[i],
_327: f => f.dartFunction,
_328: l => arrayFromDartList(Int8Array, l),
_329: (data, length) => {
          const jsBytes = new Uint8Array(length);
          const getByte = dartInstance.exports.$uint8ListGet;
          for (let i = 0; i < length; i++) {
            jsBytes[i] = getByte(data, i);
          }
          return jsBytes;
        },
_330: l => arrayFromDartList(Uint8ClampedArray, l),
_331: l => arrayFromDartList(Int16Array, l),
_332: l => arrayFromDartList(Uint16Array, l),
_333: l => arrayFromDartList(Int32Array, l),
_334: l => arrayFromDartList(Uint32Array, l),
_335: l => arrayFromDartList(Float32Array, l),
_336: l => arrayFromDartList(Float64Array, l),
_337: (data, length) => {
          const read = dartInstance.exports.$byteDataGetUint8;
          const view = new DataView(new ArrayBuffer(length));
          for (let i = 0; i < length; i++) {
              view.setUint8(i, read(data, i));
          }
          return view;
        },
_338: l => arrayFromDartList(Array, l),
_339:       (s, length) => {
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
_340:     (s, length) => {
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
_341:     (s) => {
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
_342: () => ({}),
_343: () => [],
_344: l => new Array(l),
_345: () => globalThis,
_348: (o, p) => o[p],
_349: (o, p, v) => o[p] = v,
_350: (o, m, a) => o[m].apply(o, a),
_352: o => String(o),
_353: (p, s, f) => p.then(s, f),
_354: s => {
      if (/[[\]{}()*+?.\\^$|]/.test(s)) {
          s = s.replace(/[[\]{}()*+?.\\^$|]/g, '\\$&');
      }
      return s;
    },
_357: x0 => x0.index,
_359: x0 => x0.length,
_361: (x0,x1) => x0[x1],
_362: (x0,x1) => x0.exec(x1),
_364: x0 => x0.flags,
_365: x0 => x0.multiline,
_366: x0 => x0.ignoreCase,
_367: x0 => x0.unicode,
_368: x0 => x0.dotAll,
_369: (x0,x1) => x0.lastIndex = x1,
_370: (o, p) => p in o,
_371: (o, p) => o[p],
_372: (o, p, v) => o[p] = v,
_623: (x0,x1) => x0.onscroll = x1,
_2232: () => globalThis.window,
_2293: x0 => x0.location,
_2310: x0 => x0.parent,
_2312: x0 => x0.navigator,
_2567: x0 => x0.href,
_2569: x0 => x0.origin,
_2618: x0 => x0.message,
_2619: x0 => x0.filename,
_2620: x0 => x0.lineno,
_2685: x0 => x0.userAgent,
_2736: x0 => x0.data,
_2771: x0 => x0.port1,
_2772: x0 => x0.port2,
_2777: (x0,x1) => x0.onmessage = x1,
_2779: (x0,x1) => x0.onmessageerror = x1,
_2850: (x0,x1) => x0.onmessage = x1,
_2852: (x0,x1) => x0.onmessageerror = x1,
_2854: (x0,x1) => x0.onerror = x1,
_6027: () => globalThis.document,
_6463: x0 => x0.scrollTop,
_6468: x0 => x0.scrollHeight,
_6472: x0 => x0.clientHeight,
_6491: (x0,x1) => x0.innerHTML = x1,
_8713: x0 => x0.status,
_8714: x0 => x0.ok,
_13177: () => globalThis.console
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

