
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
_136: o => o.byteOffset,
_137: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
_138: (b, o) => new DataView(b, o),
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
_203: () => new MessageChannel(),
_204: (x0,x1) => x0.postMessage(x1),
_205: (x0,x1,x2) => x0.postMessage(x1,x2),
_206: x0 => x0.close(),
_207: x0 => x0.close(),
_208: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._208(f,arguments.length,x0) }),
_209: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._209(f,arguments.length,x0) }),
_210: () => new MessageChannel(),
_211: () => new MessageChannel(),
_212: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._212(f,arguments.length,x0) }),
_213: x0 => x0.close(),
_214: () => new MessageChannel(),
_215: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._215(f,arguments.length,x0) }),
_216: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._216(f,arguments.length,x0) }),
_217: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._217(f,arguments.length,x0) }),
_218: (x0,x1,x2) => x0.postMessage(x1,x2),
_219: x0 => x0.close(),
_220: x0 => x0.close(),
_221: x0 => x0.terminate(),
_234: o => Object.keys(o),
_235: (ms, c) =>
              setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
_236: (handle) => clearTimeout(handle),
_237: (ms, c) =>
          setInterval(() => dartInstance.exports.$invokeCallback(c), ms),
_238: (handle) => clearInterval(handle),
_239: (c) =>
              queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
_240: () => Date.now(),
_241: () => new XMLHttpRequest(),
_242: (x0,x1,x2,x3) => x0.open(x1,x2,x3),
_243: (x0,x1,x2) => x0.setRequestHeader(x1,x2),
_244: (x0,x1) => x0.send(x1),
_245: x0 => x0.abort(),
_246: x0 => x0.getAllResponseHeaders(),
_247: x0 => globalThis.URL.revokeObjectURL(x0),
_248: x0 => ({type: x0}),
_249: (x0,x1) => new Blob(x0,x1),
_250: x0 => globalThis.URL.createObjectURL(x0),
_251: () => globalThis.self,
_256: (x0,x1) => x0.createElement(x1),
_259: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._259(f,arguments.length,x0) }),
_260: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._260(f,arguments.length,x0) }),
_261: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
_262: (x0,x1,x2,x3) => x0.removeEventListener(x1,x2,x3),
_280: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._280(f,arguments.length,x0) }),
_281: (x0,x1) => x0.log(x1),
_284: (x0,x1) => x0.appendChild(x1),
_285: (x0,x1,x2) => x0.scrollTo(x1,x2),
_287: (s, m) => {
          try {
            return new RegExp(s, m);
          } catch (e) {
            return String(e);
          }
        },
_288: (x0,x1) => x0.exec(x1),
_289: (x0,x1) => x0.test(x1),
_290: (x0,x1) => x0.exec(x1),
_291: (x0,x1) => x0.exec(x1),
_292: x0 => x0.pop(),
_296: (x0,x1,x2) => x0[x1] = x2,
_298: o => o === undefined,
_299: o => typeof o === 'boolean',
_300: o => typeof o === 'number',
_302: o => typeof o === 'string',
_305: o => o instanceof Int8Array,
_306: o => o instanceof Uint8Array,
_307: o => o instanceof Uint8ClampedArray,
_308: o => o instanceof Int16Array,
_309: o => o instanceof Uint16Array,
_310: o => o instanceof Int32Array,
_311: o => o instanceof Uint32Array,
_312: o => o instanceof Float32Array,
_313: o => o instanceof Float64Array,
_314: o => o instanceof ArrayBuffer,
_315: o => o instanceof DataView,
_316: o => o instanceof Array,
_317: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
_319: o => {
            const proto = Object.getPrototypeOf(o);
            return proto === Object.prototype || proto === null;
          },
_320: o => o instanceof RegExp,
_321: (l, r) => l === r,
_322: o => o,
_323: o => o,
_324: o => o,
_325: b => !!b,
_326: o => o.length,
_329: (o, i) => o[i],
_330: f => f.dartFunction,
_331: l => arrayFromDartList(Int8Array, l),
_332: (data, length) => {
          const jsBytes = new Uint8Array(length);
          const getByte = dartInstance.exports.$uint8ListGet;
          for (let i = 0; i < length; i++) {
            jsBytes[i] = getByte(data, i);
          }
          return jsBytes;
        },
_333: l => arrayFromDartList(Uint8ClampedArray, l),
_334: l => arrayFromDartList(Int16Array, l),
_335: l => arrayFromDartList(Uint16Array, l),
_336: l => arrayFromDartList(Int32Array, l),
_337: l => arrayFromDartList(Uint32Array, l),
_338: l => arrayFromDartList(Float32Array, l),
_339: l => arrayFromDartList(Float64Array, l),
_340: (data, length) => {
          const read = dartInstance.exports.$byteDataGetUint8;
          const view = new DataView(new ArrayBuffer(length));
          for (let i = 0; i < length; i++) {
              view.setUint8(i, read(data, i));
          }
          return view;
        },
_341: l => arrayFromDartList(Array, l),
_342:       (s, length) => {
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
_343:     (s, length) => {
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
_344:     (s) => {
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
_345: () => ({}),
_346: () => [],
_347: l => new Array(l),
_348: () => globalThis,
_351: (o, p) => o[p],
_352: (o, p, v) => o[p] = v,
_353: (o, m, a) => o[m].apply(o, a),
_355: o => String(o),
_357: s => {
      if (/[[\]{}()*+?.\\^$|]/.test(s)) {
          s = s.replace(/[[\]{}()*+?.\\^$|]/g, '\\$&');
      }
      return s;
    },
_360: x0 => x0.index,
_362: x0 => x0.length,
_364: (x0,x1) => x0[x1],
_365: (x0,x1) => x0.exec(x1),
_367: x0 => x0.flags,
_368: x0 => x0.multiline,
_369: x0 => x0.ignoreCase,
_370: x0 => x0.unicode,
_371: x0 => x0.dotAll,
_372: (x0,x1) => x0.lastIndex = x1,
_373: (o, p) => p in o,
_374: (o, p) => o[p],
_375: (o, p, v) => o[p] = v,
_411: (x0,x1) => x0.withCredentials = x1,
_413: x0 => x0.responseURL,
_414: x0 => x0.status,
_415: x0 => x0.statusText,
_417: (x0,x1) => x0.responseType = x1,
_418: x0 => x0.response,
_625: (x0,x1) => x0.onscroll = x1,
_2234: () => globalThis.window,
_2295: x0 => x0.location,
_2312: x0 => x0.parent,
_2314: x0 => x0.navigator,
_2569: x0 => x0.href,
_2571: x0 => x0.origin,
_2620: x0 => x0.message,
_2687: x0 => x0.userAgent,
_2738: x0 => x0.data,
_2773: x0 => x0.port1,
_2774: x0 => x0.port2,
_2779: (x0,x1) => x0.onmessage = x1,
_2781: (x0,x1) => x0.onmessageerror = x1,
_2852: (x0,x1) => x0.onmessage = x1,
_2854: (x0,x1) => x0.onmessageerror = x1,
_2855: x0 => x0.onerror,
_2856: (x0,x1) => x0.onerror = x1,
_6029: () => globalThis.document,
_6465: x0 => x0.scrollTop,
_6470: x0 => x0.scrollHeight,
_6474: x0 => x0.clientHeight,
_6493: (x0,x1) => x0.innerHTML = x1,
_13179: () => globalThis.console
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

