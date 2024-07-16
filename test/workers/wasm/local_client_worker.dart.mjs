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
_60: f => finalizeWrapper(f,x0 => dartInstance.exports._60(f,x0)),
_61: x0 => x0.close(),
_62: x0 => x0.close(),
_63: () => new MessageChannel(),
_64: f => finalizeWrapper(f,x0 => dartInstance.exports._64(f,x0)),
_65: x0 => x0.close(),
_86: () => globalThis.self,
_87: () => new MessageChannel(),
_88: x0 => x0.close(),
_89: x0 => x0.close(),
_90: x0 => x0.close(),
_91: f => finalizeWrapper(f,x0 => dartInstance.exports._91(f,x0)),
_92: f => finalizeWrapper(f,x0 => dartInstance.exports._92(f,x0)),
_93: (x0,x1) => x0.postMessage(x1),
_2566: x0 => x0.port1,
_2567: x0 => x0.port2,
_2570: (x0,x1) => x0.onmessage = x1,
_2572: (x0,x1) => x0.onmessageerror = x1,
_2602: x0 => x0.location,
_2631: (x0,x1) => x0.onmessage = x1,
_2680: x0 => x0.href,
_12762: v => stringToDartString(v.toString()),
_12773: Date.now,
_12775: s => new Date(s * 1000).getTimezoneOffset() * 60 ,
_12777: () => {
          let stackString = new Error().stack.toString();
          let frames = stackString.split('\n');
          let drop = 2;
          if (frames[0] === 'Error') {
              drop += 1;
          }
          return frames.slice(drop).join('\n');
        },
_12786: s => stringToDartString(JSON.stringify(stringFromDartString(s))),
_12787: s => printToConsole(stringFromDartString(s)),
_12800: o => Object.keys(o),
_12805: (c) =>
              queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
_12807: (a, i) => a.push(i),
_12818: a => a.length,
_12820: (a, i) => a[i],
_12821: (a, i, v) => a[i] = v,
_12823: a => a.join(''),
_12824: (o, a, b) => o.replace(a, b),
_12826: (s, t) => s.split(t),
_12827: s => s.toLowerCase(),
_12833: (s, p, i) => s.indexOf(p, i),
_12836: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
_12837: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
_12838: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
_12839: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
_12840: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
_12841: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
_12842: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
_12845: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
_12846: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
_12847: Object.is,
_12850: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
_12854: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
_12855: (b, o) => new DataView(b, o),
_12857: Function.prototype.call.bind(DataView.prototype.getUint8),
_12858: Function.prototype.call.bind(DataView.prototype.setUint8),
_12859: Function.prototype.call.bind(DataView.prototype.getInt8),
_12860: Function.prototype.call.bind(DataView.prototype.setInt8),
_12861: Function.prototype.call.bind(DataView.prototype.getUint16),
_12862: Function.prototype.call.bind(DataView.prototype.setUint16),
_12863: Function.prototype.call.bind(DataView.prototype.getInt16),
_12864: Function.prototype.call.bind(DataView.prototype.setInt16),
_12865: Function.prototype.call.bind(DataView.prototype.getUint32),
_12866: Function.prototype.call.bind(DataView.prototype.setUint32),
_12867: Function.prototype.call.bind(DataView.prototype.getInt32),
_12868: Function.prototype.call.bind(DataView.prototype.setInt32),
_12873: Function.prototype.call.bind(DataView.prototype.getFloat32),
_12875: Function.prototype.call.bind(DataView.prototype.getFloat64),
_12883: s => stringToDartString(stringFromDartString(s).toLowerCase()),
_12885: (s, m) => {
          try {
            return new RegExp(s, m);
          } catch (e) {
            return String(e);
          }
        },
_12888: (x0,x1) => x0.exec(x1),
_12889: (x0,x1) => x0.exec(x1),
_12890: x0 => x0.pop(),
_12896: o => o === undefined,
_12897: o => typeof o === 'boolean',
_12898: o => typeof o === 'number',
_12900: o => typeof o === 'string',
_12903: o => o instanceof Int8Array,
_12904: o => o instanceof Uint8Array,
_12905: o => o instanceof Uint8ClampedArray,
_12906: o => o instanceof Int16Array,
_12907: o => o instanceof Uint16Array,
_12908: o => o instanceof Int32Array,
_12909: o => o instanceof Uint32Array,
_12910: o => o instanceof Float32Array,
_12911: o => o instanceof Float64Array,
_12912: o => o instanceof ArrayBuffer,
_12913: o => o instanceof DataView,
_12914: o => o instanceof Array,
_12915: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
_12917: o => {
            const proto = Object.getPrototypeOf(o);
            return proto === Object.prototype || proto === null;
          },
_12918: o => o instanceof RegExp,
_12919: (l, r) => l === r,
_12920: o => o,
_12921: o => o,
_12922: o => o,
_12923: b => !!b,
_12924: o => o.length,
_12927: (o, i) => o[i],
_12928: f => f.dartFunction,
_12929: l => arrayFromDartList(Int8Array, l),
_12930: l => arrayFromDartList(Uint8Array, l),
_12931: l => arrayFromDartList(Uint8ClampedArray, l),
_12932: l => arrayFromDartList(Int16Array, l),
_12933: l => arrayFromDartList(Uint16Array, l),
_12934: l => arrayFromDartList(Int32Array, l),
_12935: l => arrayFromDartList(Uint32Array, l),
_12936: l => arrayFromDartList(Float32Array, l),
_12937: l => arrayFromDartList(Float64Array, l),
_12938: (data, length) => {
          const view = new DataView(new ArrayBuffer(length));
          for (let i = 0; i < length; i++) {
              view.setUint8(i, dartInstance.exports.$byteDataGetUint8(data, i));
          }
          return view;
        },
_12939: l => arrayFromDartList(Array, l),
_12940: stringFromDartString,
_12941: stringToDartString,
_12942: () => ({}),
_12943: () => [],
_12944: l => new Array(l),
_12948: (o, p) => o[p],
_12949: (o, p, v) => o[p] = v,
_12950: (o, m, a) => o[m].apply(o, a),
_12952: o => String(o),
_12957: x0 => x0.index,
_12959: x0 => x0.length,
_12961: (x0,x1) => x0[x1],
_12965: x0 => x0.flags,
_12966: x0 => x0.multiline,
_12967: x0 => x0.ignoreCase,
_12968: x0 => x0.unicode,
_12969: x0 => x0.dotAll,
_12970: (x0,x1) => x0.lastIndex = x1,
_12971: (o, p) => p in o,
_12972: (o, p) => o[p]
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

