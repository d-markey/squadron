let buildArgsList;

// `modulePromise` is a promise to the `WebAssembly.module` object to be
//   instantiated.
// `importObjectPromise` is a promise to an object that contains any additional
//   imports needed by the module that aren't provided by the standard runtime.
//   The fields on this object will be merged into the importObject with which
//   the module will be instantiated.
// This function returns a promise to the instantiated module.
export const instantiate = async (modulePromise, importObjectPromise) => {
    let dartInstance;

    function stringFromDartString(string) {
        const totalLength = dartInstance.exports.$stringLength(string);
        let result = '';
        let index = 0;
        while (index < totalLength) {
          let chunkLength = Math.min(totalLength - index, 0xFFFF);
          const array = new Array(chunkLength);
          for (let i = 0; i < chunkLength; i++) {
              array[i] = dartInstance.exports.$stringRead(string, index++);
          }
          result += String.fromCharCode(...array);
        }
        return result;
    }

    function stringToDartString(string) {
        const length = string.length;
        let range = 0;
        for (let i = 0; i < length; i++) {
            range |= string.codePointAt(i);
        }
        if (range < 256) {
            const dartString = dartInstance.exports.$stringAllocate1(length);
            for (let i = 0; i < length; i++) {
                dartInstance.exports.$stringWrite1(dartString, i, string.codePointAt(i));
            }
            return dartString;
        } else {
            const dartString = dartInstance.exports.$stringAllocate2(length);
            for (let i = 0; i < length; i++) {
                dartInstance.exports.$stringWrite2(dartString, i, string.charCodeAt(i));
            }
            return dartString;
        }
    }

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
        const length = dartInstance.exports.$listLength(list);
        const array = new constructor(length);
        for (let i = 0; i < length; i++) {
            array[i] = dartInstance.exports.$listRead(list, i);
        }
        return array;
    }

    buildArgsList = function(list) {
        const dartList = dartInstance.exports.$makeStringList();
        for (let i = 0; i < list.length; i++) {
            dartInstance.exports.$listAdd(dartList, stringToDartString(list[i]));
        }
        return dartList;
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

_48: v => stringToDartString(v.toString()),
_63: () => {
          let stackString = new Error().stack.toString();
          let frames = stackString.split('\n');
          let drop = 2;
          if (frames[0] === 'Error') {
              drop += 1;
          }
          return frames.slice(drop).join('\n');
        },
_72: s => stringToDartString(JSON.stringify(stringFromDartString(s))),
_73: s => printToConsole(stringFromDartString(s)),
_91: (c) =>
              queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
_93: (a, i) => a.push(i),
_104: a => a.length,
_106: (a, i) => a[i],
_107: (a, i, v) => a[i] = v,
_109: a => a.join(''),
_119: (s, p, i) => s.indexOf(p, i),
_122: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
_123: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
_124: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
_125: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
_126: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
_127: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
_128: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
_131: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
_132: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
_136: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
_140: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
_141: (b, o) => new DataView(b, o),
_143: Function.prototype.call.bind(DataView.prototype.getUint8),
_145: Function.prototype.call.bind(DataView.prototype.getInt8),
_147: Function.prototype.call.bind(DataView.prototype.getUint16),
_149: Function.prototype.call.bind(DataView.prototype.getInt16),
_151: Function.prototype.call.bind(DataView.prototype.getUint32),
_153: Function.prototype.call.bind(DataView.prototype.getInt32),
_159: Function.prototype.call.bind(DataView.prototype.getFloat32),
_161: Function.prototype.call.bind(DataView.prototype.getFloat64),
_182: o => o === undefined,
_183: o => typeof o === 'boolean',
_184: o => typeof o === 'number',
_186: o => typeof o === 'string',
_189: o => o instanceof Int8Array,
_190: o => o instanceof Uint8Array,
_191: o => o instanceof Uint8ClampedArray,
_192: o => o instanceof Int16Array,
_193: o => o instanceof Uint16Array,
_194: o => o instanceof Int32Array,
_195: o => o instanceof Uint32Array,
_196: o => o instanceof Float32Array,
_197: o => o instanceof Float64Array,
_198: o => o instanceof ArrayBuffer,
_199: o => o instanceof DataView,
_200: o => o instanceof Array,
_201: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
_205: (l, r) => l === r,
_206: o => o,
_207: o => o,
_208: o => o,
_209: b => !!b,
_210: o => o.length,
_213: (o, i) => o[i],
_214: f => f.dartFunction,
_215: l => arrayFromDartList(Int8Array, l),
_216: l => arrayFromDartList(Uint8Array, l),
_217: l => arrayFromDartList(Uint8ClampedArray, l),
_218: l => arrayFromDartList(Int16Array, l),
_219: l => arrayFromDartList(Uint16Array, l),
_220: l => arrayFromDartList(Int32Array, l),
_221: l => arrayFromDartList(Uint32Array, l),
_222: l => arrayFromDartList(Float32Array, l),
_223: l => arrayFromDartList(Float64Array, l),
_224: (data, length) => {
          const view = new DataView(new ArrayBuffer(length));
          for (let i = 0; i < length; i++) {
              view.setUint8(i, dartInstance.exports.$byteDataGetUint8(data, i));
          }
          return view;
        },
_225: l => arrayFromDartList(Array, l),
_226: stringFromDartString,
_227: stringToDartString,
_230: l => new Array(l),
_234: (o, p) => o[p],
_238: o => String(o)
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
    const dartMain = moduleInstance.exports.$getMain();
    const dartArgs = buildArgsList(args);
    moduleInstance.exports.$invokeMain(dartMain, dartArgs);
}

