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

_52: (x0,x1) => x0.postMessage(x1),
_53: (x0,x1,x2) => x0.postMessage(x1,x2),
_76: () => globalThis.self,
_77: () => new MessageChannel(),
_78: x0 => x0.close(),
_79: x0 => x0.close(),
_80: x0 => x0.close(),
_81: f => finalizeWrapper(f,x0 => dartInstance.exports._81(f,x0)),
_82: f => finalizeWrapper(f,x0 => dartInstance.exports._82(f,x0)),
_83: (x0,x1) => x0.postMessage(x1),
_2512: x0 => x0.port1,
_2513: x0 => x0.port2,
_2518: (x0,x1) => x0.onmessage = x1,
_2579: (x0,x1) => x0.onmessage = x1,
_12948: v => stringToDartString(v.toString()),
_12959: Date.now,
_12961: s => new Date(s * 1000).getTimezoneOffset() * 60 ,
_12963: () => {
          let stackString = new Error().stack.toString();
          let frames = stackString.split('\n');
          let drop = 2;
          if (frames[0] === 'Error') {
              drop += 1;
          }
          return frames.slice(drop).join('\n');
        },
_12964: () => typeof dartUseDateNowForTicks !== "undefined",
_12965: () => 1000 * performance.now(),
_12966: () => Date.now(),
_12972: s => stringToDartString(JSON.stringify(stringFromDartString(s))),
_12973: s => printToConsole(stringFromDartString(s)),
_12986: o => Object.keys(o),
_12987: (ms, c) =>
              setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
_12991: (c) =>
              queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
_12993: (a, i) => a.push(i),
_13004: a => a.length,
_13006: (a, i) => a[i],
_13007: (a, i, v) => a[i] = v,
_13009: a => a.join(''),
_13015: s => s.trim(),
_13019: (s, p, i) => s.indexOf(p, i),
_13022: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
_13023: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
_13024: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
_13025: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
_13026: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
_13027: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
_13028: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
_13031: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
_13032: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
_13036: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
_13040: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
_13041: (b, o) => new DataView(b, o),
_13043: Function.prototype.call.bind(DataView.prototype.getUint8),
_13044: Function.prototype.call.bind(DataView.prototype.setUint8),
_13045: Function.prototype.call.bind(DataView.prototype.getInt8),
_13046: Function.prototype.call.bind(DataView.prototype.setInt8),
_13047: Function.prototype.call.bind(DataView.prototype.getUint16),
_13048: Function.prototype.call.bind(DataView.prototype.setUint16),
_13049: Function.prototype.call.bind(DataView.prototype.getInt16),
_13050: Function.prototype.call.bind(DataView.prototype.setInt16),
_13051: Function.prototype.call.bind(DataView.prototype.getUint32),
_13052: Function.prototype.call.bind(DataView.prototype.setUint32),
_13053: Function.prototype.call.bind(DataView.prototype.getInt32),
_13054: Function.prototype.call.bind(DataView.prototype.setInt32),
_13059: Function.prototype.call.bind(DataView.prototype.getFloat32),
_13061: Function.prototype.call.bind(DataView.prototype.getFloat64),
_13071: (s, m) => {
          try {
            return new RegExp(s, m);
          } catch (e) {
            return String(e);
          }
        },
_13072: (x0,x1) => x0.exec(x1),
_13082: o => o === undefined,
_13083: o => typeof o === 'boolean',
_13084: o => typeof o === 'number',
_13086: o => typeof o === 'string',
_13089: o => o instanceof Int8Array,
_13090: o => o instanceof Uint8Array,
_13091: o => o instanceof Uint8ClampedArray,
_13092: o => o instanceof Int16Array,
_13093: o => o instanceof Uint16Array,
_13094: o => o instanceof Int32Array,
_13095: o => o instanceof Uint32Array,
_13096: o => o instanceof Float32Array,
_13097: o => o instanceof Float64Array,
_13098: o => o instanceof ArrayBuffer,
_13099: o => o instanceof DataView,
_13100: o => o instanceof Array,
_13101: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
_13103: o => {
            const proto = Object.getPrototypeOf(o);
            return proto === Object.prototype || proto === null;
          },
_13104: o => o instanceof RegExp,
_13105: (l, r) => l === r,
_13106: o => o,
_13107: o => o,
_13108: o => o,
_13109: b => !!b,
_13110: o => o.length,
_13113: (o, i) => o[i],
_13114: f => f.dartFunction,
_13115: l => arrayFromDartList(Int8Array, l),
_13116: l => arrayFromDartList(Uint8Array, l),
_13117: l => arrayFromDartList(Uint8ClampedArray, l),
_13118: l => arrayFromDartList(Int16Array, l),
_13119: l => arrayFromDartList(Uint16Array, l),
_13120: l => arrayFromDartList(Int32Array, l),
_13121: l => arrayFromDartList(Uint32Array, l),
_13122: l => arrayFromDartList(Float32Array, l),
_13123: l => arrayFromDartList(Float64Array, l),
_13124: (data, length) => {
          const view = new DataView(new ArrayBuffer(length));
          for (let i = 0; i < length; i++) {
              view.setUint8(i, dartInstance.exports.$byteDataGetUint8(data, i));
          }
          return view;
        },
_13125: l => arrayFromDartList(Array, l),
_13126: stringFromDartString,
_13127: stringToDartString,
_13128: () => ({}),
_13129: () => [],
_13130: l => new Array(l),
_13134: (o, p) => o[p],
_13135: (o, p, v) => o[p] = v,
_13136: (o, m, a) => o[m].apply(o, a),
_13138: o => String(o),
_13145: x0 => x0.length,
_13147: (x0,x1) => x0[x1],
_13151: x0 => x0.flags,
_13157: (o, p) => p in o,
_13158: (o, p) => o[p]
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

