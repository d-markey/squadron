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

_72: () => globalThis.self,
_73: (x0,x1) => x0.postMessage(x1),
_74: f => finalizeWrapper(f,x0 => dartInstance.exports._74(f,x0)),
_2469: x0 => x0.data,
_2571: (x0,x1) => x0.onmessage = x1,
_12940: v => stringToDartString(v.toString()),
_12951: Date.now,
_12953: s => new Date(s * 1000).getTimezoneOffset() * 60 ,
_12955: () => {
          let stackString = new Error().stack.toString();
          let frames = stackString.split('\n');
          let drop = 2;
          if (frames[0] === 'Error') {
              drop += 1;
          }
          return frames.slice(drop).join('\n');
        },
_12964: s => stringToDartString(JSON.stringify(stringFromDartString(s))),
_12965: s => printToConsole(stringFromDartString(s)),
_12978: o => Object.keys(o),
_12983: (c) =>
              queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
_12985: (a, i) => a.push(i),
_12996: a => a.length,
_12998: (a, i) => a[i],
_12999: (a, i, v) => a[i] = v,
_13001: a => a.join(''),
_13011: (s, p, i) => s.indexOf(p, i),
_13014: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
_13015: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
_13016: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
_13017: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
_13018: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
_13019: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
_13020: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
_13023: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
_13024: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
_13028: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
_13032: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
_13033: (b, o) => new DataView(b, o),
_13035: Function.prototype.call.bind(DataView.prototype.getUint8),
_13037: Function.prototype.call.bind(DataView.prototype.getInt8),
_13039: Function.prototype.call.bind(DataView.prototype.getUint16),
_13041: Function.prototype.call.bind(DataView.prototype.getInt16),
_13043: Function.prototype.call.bind(DataView.prototype.getUint32),
_13045: Function.prototype.call.bind(DataView.prototype.getInt32),
_13051: Function.prototype.call.bind(DataView.prototype.getFloat32),
_13053: Function.prototype.call.bind(DataView.prototype.getFloat64),
_13074: o => o === undefined,
_13075: o => typeof o === 'boolean',
_13076: o => typeof o === 'number',
_13078: o => typeof o === 'string',
_13081: o => o instanceof Int8Array,
_13082: o => o instanceof Uint8Array,
_13083: o => o instanceof Uint8ClampedArray,
_13084: o => o instanceof Int16Array,
_13085: o => o instanceof Uint16Array,
_13086: o => o instanceof Int32Array,
_13087: o => o instanceof Uint32Array,
_13088: o => o instanceof Float32Array,
_13089: o => o instanceof Float64Array,
_13090: o => o instanceof ArrayBuffer,
_13091: o => o instanceof DataView,
_13092: o => o instanceof Array,
_13093: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
_13095: o => {
            const proto = Object.getPrototypeOf(o);
            return proto === Object.prototype || proto === null;
          },
_13097: (l, r) => l === r,
_13098: o => o,
_13099: o => o,
_13100: o => o,
_13101: b => !!b,
_13102: o => o.length,
_13105: (o, i) => o[i],
_13106: f => f.dartFunction,
_13107: l => arrayFromDartList(Int8Array, l),
_13108: l => arrayFromDartList(Uint8Array, l),
_13109: l => arrayFromDartList(Uint8ClampedArray, l),
_13110: l => arrayFromDartList(Int16Array, l),
_13111: l => arrayFromDartList(Uint16Array, l),
_13112: l => arrayFromDartList(Int32Array, l),
_13113: l => arrayFromDartList(Uint32Array, l),
_13114: l => arrayFromDartList(Float32Array, l),
_13115: l => arrayFromDartList(Float64Array, l),
_13116: (data, length) => {
          const view = new DataView(new ArrayBuffer(length));
          for (let i = 0; i < length; i++) {
              view.setUint8(i, dartInstance.exports.$byteDataGetUint8(data, i));
          }
          return view;
        },
_13117: l => arrayFromDartList(Array, l),
_13118: stringFromDartString,
_13119: stringToDartString,
_13120: () => ({}),
_13121: () => [],
_13122: l => new Array(l),
_13126: (o, p) => o[p],
_13127: (o, p, v) => o[p] = v,
_13128: (o, m, a) => o[m].apply(o, a),
_13130: o => String(o)
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

