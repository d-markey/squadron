
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
_85: s => JSON.stringify(s),
_86: s => printToConsole(s),
_87: a => a.join(''),
_93: s => s.trim(),
_97: (s, p, i) => s.indexOf(p, i),
_103: (a, i) => a.push(i),
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
_158: Function.prototype.call.bind(DataView.prototype.getFloat64),
_166: (x0,x1) => x0.postMessage(x1),
_167: (x0,x1,x2) => x0.postMessage(x1,x2),
_190: () => globalThis.self,
_191: () => new MessageChannel(),
_192: x0 => x0.close(),
_193: x0 => x0.close(),
_194: x0 => x0.close(),
_195: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._195(f,arguments.length,x0) }),
_196: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._196(f,arguments.length,x0) }),
_197: (x0,x1) => x0.postMessage(x1),
_210: o => Object.keys(o),
_211: (ms, c) =>
              setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
_215: (c) =>
              queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
_256: (s, m) => {
          try {
            return new RegExp(s, m);
          } catch (e) {
            return String(e);
          }
        },
_257: (x0,x1) => x0.exec(x1),
_267: o => o === undefined,
_268: o => typeof o === 'boolean',
_269: o => typeof o === 'number',
_271: o => typeof o === 'string',
_274: o => o instanceof Int8Array,
_275: o => o instanceof Uint8Array,
_276: o => o instanceof Uint8ClampedArray,
_277: o => o instanceof Int16Array,
_278: o => o instanceof Uint16Array,
_279: o => o instanceof Int32Array,
_280: o => o instanceof Uint32Array,
_281: o => o instanceof Float32Array,
_282: o => o instanceof Float64Array,
_283: o => o instanceof ArrayBuffer,
_284: o => o instanceof DataView,
_285: o => o instanceof Array,
_286: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
_288: o => {
            const proto = Object.getPrototypeOf(o);
            return proto === Object.prototype || proto === null;
          },
_289: o => o instanceof RegExp,
_290: (l, r) => l === r,
_291: o => o,
_292: o => o,
_293: o => o,
_294: b => !!b,
_295: o => o.length,
_298: (o, i) => o[i],
_299: f => f.dartFunction,
_300: l => arrayFromDartList(Int8Array, l),
_301: (data, length) => {
          const jsBytes = new Uint8Array(length);
          const getByte = dartInstance.exports.$uint8ListGet;
          for (let i = 0; i < length; i++) {
            jsBytes[i] = getByte(data, i);
          }
          return jsBytes;
        },
_302: l => arrayFromDartList(Uint8ClampedArray, l),
_303: l => arrayFromDartList(Int16Array, l),
_304: l => arrayFromDartList(Uint16Array, l),
_305: l => arrayFromDartList(Int32Array, l),
_306: l => arrayFromDartList(Uint32Array, l),
_307: l => arrayFromDartList(Float32Array, l),
_308: l => arrayFromDartList(Float64Array, l),
_309: (data, length) => {
          const read = dartInstance.exports.$byteDataGetUint8;
          const view = new DataView(new ArrayBuffer(length));
          for (let i = 0; i < length; i++) {
              view.setUint8(i, read(data, i));
          }
          return view;
        },
_310: l => arrayFromDartList(Array, l),
_311:       (s, length) => {
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
_312:     (s, length) => {
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
_313:     (s) => {
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
_314: () => ({}),
_315: () => [],
_316: l => new Array(l),
_320: (o, p) => o[p],
_321: (o, p, v) => o[p] = v,
_322: (o, m, a) => o[m].apply(o, a),
_324: o => String(o),
_331: x0 => x0.length,
_333: (x0,x1) => x0[x1],
_336: x0 => x0.flags,
_342: (o, p) => p in o,
_343: (o, p) => o[p],
_2742: x0 => x0.port1,
_2743: x0 => x0.port2,
_2748: (x0,x1) => x0.onmessage = x1,
_2809: (x0,x1) => x0.onmessage = x1
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

