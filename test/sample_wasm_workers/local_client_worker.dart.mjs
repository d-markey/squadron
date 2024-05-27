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

_55: (x0,x1) => x0.postMessage(x1),
_56: (x0,x1,x2) => x0.postMessage(x1,x2),
_58: () => new MessageChannel(),
_59: f => finalizeWrapper(f,x0 => dartInstance.exports._59(f,x0)),
_60: x0 => x0.close(),
_61: x0 => x0.close(),
_62: () => new MessageChannel(),
_63: f => finalizeWrapper(f,x0 => dartInstance.exports._63(f,x0)),
_64: x0 => x0.close(),
_81: () => globalThis.self,
_83: () => globalThis.self,
_84: () => new MessageChannel(),
_85: x0 => x0.close(),
_86: x0 => x0.close(),
_87: x0 => x0.close(),
_88: f => finalizeWrapper(f,x0 => dartInstance.exports._88(f,x0)),
_89: f => finalizeWrapper(f,x0 => dartInstance.exports._89(f,x0)),
_90: (x0,x1) => x0.postMessage(x1),
_119: (x0,x1) => x0.log(x1),
_1918: () => globalThis.window,
_2529: x0 => x0.data,
_2564: x0 => x0.port1,
_2565: x0 => x0.port2,
_2568: (x0,x1) => x0.onmessage = x1,
_2629: (x0,x1) => x0.onmessage = x1,
_12737: () => globalThis.console,
_12761: v => stringToDartString(v.toString()),
_12772: Date.now,
_12774: s => new Date(s * 1000).getTimezoneOffset() * 60 ,
_12776: () => {
          let stackString = new Error().stack.toString();
          let frames = stackString.split('\n');
          let drop = 2;
          if (frames[0] === 'Error') {
              drop += 1;
          }
          return frames.slice(drop).join('\n');
        },
_12785: s => stringToDartString(JSON.stringify(stringFromDartString(s))),
_12786: s => printToConsole(stringFromDartString(s)),
_12799: o => Object.keys(o),
_12804: (c) =>
              queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
_12806: (a, i) => a.push(i),
_12817: a => a.length,
_12819: (a, i) => a[i],
_12820: (a, i, v) => a[i] = v,
_12822: a => a.join(''),
_12823: (o, a, b) => o.replace(a, b),
_12825: (s, t) => s.split(t),
_12832: (s, p, i) => s.indexOf(p, i),
_12835: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
_12836: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
_12837: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
_12838: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
_12839: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
_12840: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
_12841: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
_12844: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
_12845: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
_12849: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
_12853: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
_12854: (b, o) => new DataView(b, o),
_12856: Function.prototype.call.bind(DataView.prototype.getUint8),
_12857: Function.prototype.call.bind(DataView.prototype.setUint8),
_12858: Function.prototype.call.bind(DataView.prototype.getInt8),
_12859: Function.prototype.call.bind(DataView.prototype.setInt8),
_12860: Function.prototype.call.bind(DataView.prototype.getUint16),
_12861: Function.prototype.call.bind(DataView.prototype.setUint16),
_12862: Function.prototype.call.bind(DataView.prototype.getInt16),
_12863: Function.prototype.call.bind(DataView.prototype.setInt16),
_12864: Function.prototype.call.bind(DataView.prototype.getUint32),
_12865: Function.prototype.call.bind(DataView.prototype.setUint32),
_12866: Function.prototype.call.bind(DataView.prototype.getInt32),
_12867: Function.prototype.call.bind(DataView.prototype.setInt32),
_12872: Function.prototype.call.bind(DataView.prototype.getFloat32),
_12874: Function.prototype.call.bind(DataView.prototype.getFloat64),
_12884: (s, m) => {
          try {
            return new RegExp(s, m);
          } catch (e) {
            return String(e);
          }
        },
_12887: (x0,x1) => x0.exec(x1),
_12888: (x0,x1) => x0.exec(x1),
_12889: x0 => x0.pop(),
_12895: o => o === undefined,
_12896: o => typeof o === 'boolean',
_12897: o => typeof o === 'number',
_12899: o => typeof o === 'string',
_12902: o => o instanceof Int8Array,
_12903: o => o instanceof Uint8Array,
_12904: o => o instanceof Uint8ClampedArray,
_12905: o => o instanceof Int16Array,
_12906: o => o instanceof Uint16Array,
_12907: o => o instanceof Int32Array,
_12908: o => o instanceof Uint32Array,
_12909: o => o instanceof Float32Array,
_12910: o => o instanceof Float64Array,
_12911: o => o instanceof ArrayBuffer,
_12912: o => o instanceof DataView,
_12913: o => o instanceof Array,
_12914: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
_12916: o => {
            const proto = Object.getPrototypeOf(o);
            return proto === Object.prototype || proto === null;
          },
_12917: o => o instanceof RegExp,
_12918: (l, r) => l === r,
_12919: o => o,
_12920: o => o,
_12921: o => o,
_12922: b => !!b,
_12923: o => o.length,
_12926: (o, i) => o[i],
_12927: f => f.dartFunction,
_12928: l => arrayFromDartList(Int8Array, l),
_12929: l => arrayFromDartList(Uint8Array, l),
_12930: l => arrayFromDartList(Uint8ClampedArray, l),
_12931: l => arrayFromDartList(Int16Array, l),
_12932: l => arrayFromDartList(Uint16Array, l),
_12933: l => arrayFromDartList(Int32Array, l),
_12934: l => arrayFromDartList(Uint32Array, l),
_12935: l => arrayFromDartList(Float32Array, l),
_12936: l => arrayFromDartList(Float64Array, l),
_12937: (data, length) => {
          const view = new DataView(new ArrayBuffer(length));
          for (let i = 0; i < length; i++) {
              view.setUint8(i, dartInstance.exports.$byteDataGetUint8(data, i));
          }
          return view;
        },
_12938: l => arrayFromDartList(Array, l),
_12939: stringFromDartString,
_12940: stringToDartString,
_12941: () => ({}),
_12942: () => [],
_12943: l => new Array(l),
_12947: (o, p) => o[p],
_12948: (o, p, v) => o[p] = v,
_12949: (o, m, a) => o[m].apply(o, a),
_12951: o => String(o),
_12956: x0 => x0.index,
_12958: x0 => x0.length,
_12960: (x0,x1) => x0[x1],
_12964: x0 => x0.flags,
_12965: x0 => x0.multiline,
_12966: x0 => x0.ignoreCase,
_12967: x0 => x0.unicode,
_12968: x0 => x0.dotAll,
_12969: (x0,x1) => x0.lastIndex = x1
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

