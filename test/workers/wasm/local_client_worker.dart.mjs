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

_56: (x0,x1) => x0.postMessage(x1),
_57: (x0,x1,x2) => x0.postMessage(x1,x2),
_58: x0 => x0.close(),
_59: x0 => x0.close(),
_60: f => finalizeWrapper(f,x0 => dartInstance.exports._60(f,x0)),
_61: f => finalizeWrapper(f,x0 => dartInstance.exports._61(f,x0)),
_62: () => new MessageChannel(),
_63: () => new MessageChannel(),
_80: () => globalThis.self,
_81: () => new MessageChannel(),
_82: x0 => x0.close(),
_83: x0 => x0.close(),
_84: x0 => x0.close(),
_85: f => finalizeWrapper(f,x0 => dartInstance.exports._85(f,x0)),
_86: f => finalizeWrapper(f,x0 => dartInstance.exports._86(f,x0)),
_87: (x0,x1) => x0.postMessage(x1),
_2516: x0 => x0.port1,
_2517: x0 => x0.port2,
_2522: (x0,x1) => x0.onmessage = x1,
_2524: (x0,x1) => x0.onmessageerror = x1,
_2583: (x0,x1) => x0.onmessage = x1,
_12952: v => stringToDartString(v.toString()),
_12963: Date.now,
_12965: s => new Date(s * 1000).getTimezoneOffset() * 60 ,
_12967: () => {
          let stackString = new Error().stack.toString();
          let frames = stackString.split('\n');
          let drop = 2;
          if (frames[0] === 'Error') {
              drop += 1;
          }
          return frames.slice(drop).join('\n');
        },
_12976: s => stringToDartString(JSON.stringify(stringFromDartString(s))),
_12977: s => printToConsole(stringFromDartString(s)),
_12990: o => Object.keys(o),
_12995: (c) =>
              queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
_12997: (a, i) => a.push(i),
_13008: a => a.length,
_13010: (a, i) => a[i],
_13011: (a, i, v) => a[i] = v,
_13013: a => a.join(''),
_13014: (o, a, b) => o.replace(a, b),
_13016: (s, t) => s.split(t),
_13017: s => s.toLowerCase(),
_13023: (s, p, i) => s.indexOf(p, i),
_13026: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
_13027: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
_13028: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
_13029: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
_13030: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
_13031: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
_13032: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
_13035: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
_13036: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
_13037: Object.is,
_13040: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
_13044: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
_13045: (b, o) => new DataView(b, o),
_13047: Function.prototype.call.bind(DataView.prototype.getUint8),
_13048: Function.prototype.call.bind(DataView.prototype.setUint8),
_13049: Function.prototype.call.bind(DataView.prototype.getInt8),
_13050: Function.prototype.call.bind(DataView.prototype.setInt8),
_13051: Function.prototype.call.bind(DataView.prototype.getUint16),
_13052: Function.prototype.call.bind(DataView.prototype.setUint16),
_13053: Function.prototype.call.bind(DataView.prototype.getInt16),
_13054: Function.prototype.call.bind(DataView.prototype.setInt16),
_13055: Function.prototype.call.bind(DataView.prototype.getUint32),
_13056: Function.prototype.call.bind(DataView.prototype.setUint32),
_13057: Function.prototype.call.bind(DataView.prototype.getInt32),
_13058: Function.prototype.call.bind(DataView.prototype.setInt32),
_13063: Function.prototype.call.bind(DataView.prototype.getFloat32),
_13065: Function.prototype.call.bind(DataView.prototype.getFloat64),
_13073: s => stringToDartString(stringFromDartString(s).toLowerCase()),
_13075: (s, m) => {
          try {
            return new RegExp(s, m);
          } catch (e) {
            return String(e);
          }
        },
_13078: (x0,x1) => x0.exec(x1),
_13079: (x0,x1) => x0.exec(x1),
_13080: x0 => x0.pop(),
_13086: o => o === undefined,
_13087: o => typeof o === 'boolean',
_13088: o => typeof o === 'number',
_13090: o => typeof o === 'string',
_13093: o => o instanceof Int8Array,
_13094: o => o instanceof Uint8Array,
_13095: o => o instanceof Uint8ClampedArray,
_13096: o => o instanceof Int16Array,
_13097: o => o instanceof Uint16Array,
_13098: o => o instanceof Int32Array,
_13099: o => o instanceof Uint32Array,
_13100: o => o instanceof Float32Array,
_13101: o => o instanceof Float64Array,
_13102: o => o instanceof ArrayBuffer,
_13103: o => o instanceof DataView,
_13104: o => o instanceof Array,
_13105: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
_13107: o => {
            const proto = Object.getPrototypeOf(o);
            return proto === Object.prototype || proto === null;
          },
_13108: o => o instanceof RegExp,
_13109: (l, r) => l === r,
_13110: o => o,
_13111: o => o,
_13112: o => o,
_13113: b => !!b,
_13114: o => o.length,
_13117: (o, i) => o[i],
_13118: f => f.dartFunction,
_13119: l => arrayFromDartList(Int8Array, l),
_13120: l => arrayFromDartList(Uint8Array, l),
_13121: l => arrayFromDartList(Uint8ClampedArray, l),
_13122: l => arrayFromDartList(Int16Array, l),
_13123: l => arrayFromDartList(Uint16Array, l),
_13124: l => arrayFromDartList(Int32Array, l),
_13125: l => arrayFromDartList(Uint32Array, l),
_13126: l => arrayFromDartList(Float32Array, l),
_13127: l => arrayFromDartList(Float64Array, l),
_13128: (data, length) => {
          const view = new DataView(new ArrayBuffer(length));
          for (let i = 0; i < length; i++) {
              view.setUint8(i, dartInstance.exports.$byteDataGetUint8(data, i));
          }
          return view;
        },
_13129: l => arrayFromDartList(Array, l),
_13130: stringFromDartString,
_13131: stringToDartString,
_13132: () => ({}),
_13133: () => [],
_13134: l => new Array(l),
_13138: (o, p) => o[p],
_13139: (o, p, v) => o[p] = v,
_13140: (o, m, a) => o[m].apply(o, a),
_13142: o => String(o),
_13147: x0 => x0.index,
_13149: x0 => x0.length,
_13151: (x0,x1) => x0[x1],
_13155: x0 => x0.flags,
_13156: x0 => x0.multiline,
_13157: x0 => x0.ignoreCase,
_13158: x0 => x0.unicode,
_13159: x0 => x0.dotAll,
_13160: (x0,x1) => x0.lastIndex = x1,
_13161: (o, p) => p in o,
_13162: (o, p) => o[p]
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

