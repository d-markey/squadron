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

_75: () => globalThis.self,
_76: (x0,x1) => x0.postMessage(x1),
_77: f => finalizeWrapper(f,x0 => dartInstance.exports._77(f,x0)),
_2487: x0 => x0.data,
_2588: (x0,x1) => x0.onmessage = x1,
_12721: v => stringToDartString(v.toString()),
_12732: Date.now,
_12734: s => new Date(s * 1000).getTimezoneOffset() * 60 ,
_12736: () => {
          let stackString = new Error().stack.toString();
          let frames = stackString.split('\n');
          let drop = 2;
          if (frames[0] === 'Error') {
              drop += 1;
          }
          return frames.slice(drop).join('\n');
        },
_12745: s => stringToDartString(JSON.stringify(stringFromDartString(s))),
_12746: s => printToConsole(stringFromDartString(s)),
_12759: o => Object.keys(o),
_12764: (c) =>
              queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
_12766: (a, i) => a.push(i),
_12777: a => a.length,
_12779: (a, i) => a[i],
_12780: (a, i, v) => a[i] = v,
_12782: a => a.join(''),
_12792: (s, p, i) => s.indexOf(p, i),
_12795: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
_12796: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
_12797: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
_12798: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
_12799: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
_12800: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
_12801: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
_12804: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
_12805: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
_12809: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
_12813: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
_12814: (b, o) => new DataView(b, o),
_12816: Function.prototype.call.bind(DataView.prototype.getUint8),
_12818: Function.prototype.call.bind(DataView.prototype.getInt8),
_12820: Function.prototype.call.bind(DataView.prototype.getUint16),
_12822: Function.prototype.call.bind(DataView.prototype.getInt16),
_12824: Function.prototype.call.bind(DataView.prototype.getUint32),
_12826: Function.prototype.call.bind(DataView.prototype.getInt32),
_12832: Function.prototype.call.bind(DataView.prototype.getFloat32),
_12834: Function.prototype.call.bind(DataView.prototype.getFloat64),
_12855: o => o === undefined,
_12856: o => typeof o === 'boolean',
_12857: o => typeof o === 'number',
_12859: o => typeof o === 'string',
_12862: o => o instanceof Int8Array,
_12863: o => o instanceof Uint8Array,
_12864: o => o instanceof Uint8ClampedArray,
_12865: o => o instanceof Int16Array,
_12866: o => o instanceof Uint16Array,
_12867: o => o instanceof Int32Array,
_12868: o => o instanceof Uint32Array,
_12869: o => o instanceof Float32Array,
_12870: o => o instanceof Float64Array,
_12871: o => o instanceof ArrayBuffer,
_12872: o => o instanceof DataView,
_12873: o => o instanceof Array,
_12874: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
_12876: o => {
            const proto = Object.getPrototypeOf(o);
            return proto === Object.prototype || proto === null;
          },
_12878: (l, r) => l === r,
_12879: o => o,
_12880: o => o,
_12881: o => o,
_12882: b => !!b,
_12883: o => o.length,
_12886: (o, i) => o[i],
_12887: f => f.dartFunction,
_12888: l => arrayFromDartList(Int8Array, l),
_12889: l => arrayFromDartList(Uint8Array, l),
_12890: l => arrayFromDartList(Uint8ClampedArray, l),
_12891: l => arrayFromDartList(Int16Array, l),
_12892: l => arrayFromDartList(Uint16Array, l),
_12893: l => arrayFromDartList(Int32Array, l),
_12894: l => arrayFromDartList(Uint32Array, l),
_12895: l => arrayFromDartList(Float32Array, l),
_12896: l => arrayFromDartList(Float64Array, l),
_12897: (data, length) => {
          const view = new DataView(new ArrayBuffer(length));
          for (let i = 0; i < length; i++) {
              view.setUint8(i, dartInstance.exports.$byteDataGetUint8(data, i));
          }
          return view;
        },
_12898: l => arrayFromDartList(Array, l),
_12899: stringFromDartString,
_12900: stringToDartString,
_12901: () => ({}),
_12902: () => [],
_12903: l => new Array(l),
_12907: (o, p) => o[p],
_12908: (o, p, v) => o[p] = v,
_12909: (o, m, a) => o[m].apply(o, a),
_12911: o => String(o)
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

