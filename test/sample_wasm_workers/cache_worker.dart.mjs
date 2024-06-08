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

_51: (x0,x1) => x0.postMessage(x1),
_52: (x0,x1,x2) => x0.postMessage(x1,x2),
_78: () => globalThis.self,
_79: () => new MessageChannel(),
_80: x0 => x0.close(),
_81: x0 => x0.close(),
_82: x0 => x0.close(),
_83: f => finalizeWrapper(f,x0 => dartInstance.exports._83(f,x0)),
_84: f => finalizeWrapper(f,x0 => dartInstance.exports._84(f,x0)),
_85: (x0,x1) => x0.postMessage(x1),
_2524: x0 => x0.data,
_2559: x0 => x0.port1,
_2560: x0 => x0.port2,
_2563: (x0,x1) => x0.onmessage = x1,
_2624: (x0,x1) => x0.onmessage = x1,
_12756: v => stringToDartString(v.toString()),
_12767: Date.now,
_12769: s => new Date(s * 1000).getTimezoneOffset() * 60 ,
_12771: () => {
          let stackString = new Error().stack.toString();
          let frames = stackString.split('\n');
          let drop = 2;
          if (frames[0] === 'Error') {
              drop += 1;
          }
          return frames.slice(drop).join('\n');
        },
_12780: s => stringToDartString(JSON.stringify(stringFromDartString(s))),
_12781: s => printToConsole(stringFromDartString(s)),
_12794: o => Object.keys(o),
_12799: (c) =>
              queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
_12801: (a, i) => a.push(i),
_12812: a => a.length,
_12814: (a, i) => a[i],
_12815: (a, i, v) => a[i] = v,
_12817: a => a.join(''),
_12827: (s, p, i) => s.indexOf(p, i),
_12830: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
_12831: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
_12832: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
_12833: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
_12834: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
_12835: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
_12836: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
_12839: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
_12840: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
_12844: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
_12848: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
_12849: (b, o) => new DataView(b, o),
_12851: Function.prototype.call.bind(DataView.prototype.getUint8),
_12852: Function.prototype.call.bind(DataView.prototype.setUint8),
_12853: Function.prototype.call.bind(DataView.prototype.getInt8),
_12854: Function.prototype.call.bind(DataView.prototype.setInt8),
_12855: Function.prototype.call.bind(DataView.prototype.getUint16),
_12856: Function.prototype.call.bind(DataView.prototype.setUint16),
_12857: Function.prototype.call.bind(DataView.prototype.getInt16),
_12858: Function.prototype.call.bind(DataView.prototype.setInt16),
_12859: Function.prototype.call.bind(DataView.prototype.getUint32),
_12860: Function.prototype.call.bind(DataView.prototype.setUint32),
_12861: Function.prototype.call.bind(DataView.prototype.getInt32),
_12862: Function.prototype.call.bind(DataView.prototype.setInt32),
_12867: Function.prototype.call.bind(DataView.prototype.getFloat32),
_12869: Function.prototype.call.bind(DataView.prototype.getFloat64),
_12890: o => o === undefined,
_12891: o => typeof o === 'boolean',
_12892: o => typeof o === 'number',
_12894: o => typeof o === 'string',
_12897: o => o instanceof Int8Array,
_12898: o => o instanceof Uint8Array,
_12899: o => o instanceof Uint8ClampedArray,
_12900: o => o instanceof Int16Array,
_12901: o => o instanceof Uint16Array,
_12902: o => o instanceof Int32Array,
_12903: o => o instanceof Uint32Array,
_12904: o => o instanceof Float32Array,
_12905: o => o instanceof Float64Array,
_12906: o => o instanceof ArrayBuffer,
_12907: o => o instanceof DataView,
_12908: o => o instanceof Array,
_12909: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
_12911: o => {
            const proto = Object.getPrototypeOf(o);
            return proto === Object.prototype || proto === null;
          },
_12913: (l, r) => l === r,
_12914: o => o,
_12915: o => o,
_12916: o => o,
_12917: b => !!b,
_12918: o => o.length,
_12921: (o, i) => o[i],
_12922: f => f.dartFunction,
_12923: l => arrayFromDartList(Int8Array, l),
_12924: l => arrayFromDartList(Uint8Array, l),
_12925: l => arrayFromDartList(Uint8ClampedArray, l),
_12926: l => arrayFromDartList(Int16Array, l),
_12927: l => arrayFromDartList(Uint16Array, l),
_12928: l => arrayFromDartList(Int32Array, l),
_12929: l => arrayFromDartList(Uint32Array, l),
_12930: l => arrayFromDartList(Float32Array, l),
_12931: l => arrayFromDartList(Float64Array, l),
_12932: (data, length) => {
          const view = new DataView(new ArrayBuffer(length));
          for (let i = 0; i < length; i++) {
              view.setUint8(i, dartInstance.exports.$byteDataGetUint8(data, i));
          }
          return view;
        },
_12933: l => arrayFromDartList(Array, l),
_12934: stringFromDartString,
_12935: stringToDartString,
_12936: () => ({}),
_12937: () => [],
_12938: l => new Array(l),
_12942: (o, p) => o[p],
_12943: (o, p, v) => o[p] = v,
_12944: (o, m, a) => o[m].apply(o, a),
_12946: o => String(o)
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

