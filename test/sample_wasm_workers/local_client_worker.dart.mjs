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

_54: (x0,x1) => x0.postMessage(x1),
_55: (x0,x1,x2) => x0.postMessage(x1,x2),
_57: () => new MessageChannel(),
_58: f => finalizeWrapper(f,x0 => dartInstance.exports._58(f,x0)),
_59: x0 => x0.close(),
_60: x0 => x0.close(),
_61: () => new MessageChannel(),
_62: f => finalizeWrapper(f,x0 => dartInstance.exports._62(f,x0)),
_63: x0 => x0.close(),
_80: () => globalThis.self,
_82: () => globalThis.self,
_83: () => new MessageChannel(),
_84: x0 => x0.close(),
_85: x0 => x0.close(),
_86: x0 => x0.close(),
_87: f => finalizeWrapper(f,x0 => dartInstance.exports._87(f,x0)),
_88: f => finalizeWrapper(f,x0 => dartInstance.exports._88(f,x0)),
_89: (x0,x1) => x0.postMessage(x1),
_1917: () => globalThis.window,
_2528: x0 => x0.data,
_2563: x0 => x0.port1,
_2564: x0 => x0.port2,
_2567: (x0,x1) => x0.onmessage = x1,
_2628: (x0,x1) => x0.onmessage = x1,
_12760: v => stringToDartString(v.toString()),
_12771: Date.now,
_12773: s => new Date(s * 1000).getTimezoneOffset() * 60 ,
_12775: () => {
          let stackString = new Error().stack.toString();
          let frames = stackString.split('\n');
          let drop = 2;
          if (frames[0] === 'Error') {
              drop += 1;
          }
          return frames.slice(drop).join('\n');
        },
_12784: s => stringToDartString(JSON.stringify(stringFromDartString(s))),
_12785: s => printToConsole(stringFromDartString(s)),
_12798: o => Object.keys(o),
_12803: (c) =>
              queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
_12805: (a, i) => a.push(i),
_12816: a => a.length,
_12818: (a, i) => a[i],
_12819: (a, i, v) => a[i] = v,
_12821: a => a.join(''),
_12822: (o, a, b) => o.replace(a, b),
_12824: (s, t) => s.split(t),
_12831: (s, p, i) => s.indexOf(p, i),
_12834: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
_12835: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
_12836: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
_12837: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
_12838: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
_12839: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
_12840: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
_12843: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
_12844: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
_12848: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
_12852: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
_12853: (b, o) => new DataView(b, o),
_12855: Function.prototype.call.bind(DataView.prototype.getUint8),
_12856: Function.prototype.call.bind(DataView.prototype.setUint8),
_12857: Function.prototype.call.bind(DataView.prototype.getInt8),
_12858: Function.prototype.call.bind(DataView.prototype.setInt8),
_12859: Function.prototype.call.bind(DataView.prototype.getUint16),
_12860: Function.prototype.call.bind(DataView.prototype.setUint16),
_12861: Function.prototype.call.bind(DataView.prototype.getInt16),
_12862: Function.prototype.call.bind(DataView.prototype.setInt16),
_12863: Function.prototype.call.bind(DataView.prototype.getUint32),
_12864: Function.prototype.call.bind(DataView.prototype.setUint32),
_12865: Function.prototype.call.bind(DataView.prototype.getInt32),
_12866: Function.prototype.call.bind(DataView.prototype.setInt32),
_12871: Function.prototype.call.bind(DataView.prototype.getFloat32),
_12873: Function.prototype.call.bind(DataView.prototype.getFloat64),
_12883: (s, m) => {
          try {
            return new RegExp(s, m);
          } catch (e) {
            return String(e);
          }
        },
_12886: (x0,x1) => x0.exec(x1),
_12887: (x0,x1) => x0.exec(x1),
_12888: x0 => x0.pop(),
_12894: o => o === undefined,
_12895: o => typeof o === 'boolean',
_12896: o => typeof o === 'number',
_12898: o => typeof o === 'string',
_12901: o => o instanceof Int8Array,
_12902: o => o instanceof Uint8Array,
_12903: o => o instanceof Uint8ClampedArray,
_12904: o => o instanceof Int16Array,
_12905: o => o instanceof Uint16Array,
_12906: o => o instanceof Int32Array,
_12907: o => o instanceof Uint32Array,
_12908: o => o instanceof Float32Array,
_12909: o => o instanceof Float64Array,
_12910: o => o instanceof ArrayBuffer,
_12911: o => o instanceof DataView,
_12912: o => o instanceof Array,
_12913: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
_12915: o => {
            const proto = Object.getPrototypeOf(o);
            return proto === Object.prototype || proto === null;
          },
_12916: o => o instanceof RegExp,
_12917: (l, r) => l === r,
_12918: o => o,
_12919: o => o,
_12920: o => o,
_12921: b => !!b,
_12922: o => o.length,
_12925: (o, i) => o[i],
_12926: f => f.dartFunction,
_12927: l => arrayFromDartList(Int8Array, l),
_12928: l => arrayFromDartList(Uint8Array, l),
_12929: l => arrayFromDartList(Uint8ClampedArray, l),
_12930: l => arrayFromDartList(Int16Array, l),
_12931: l => arrayFromDartList(Uint16Array, l),
_12932: l => arrayFromDartList(Int32Array, l),
_12933: l => arrayFromDartList(Uint32Array, l),
_12934: l => arrayFromDartList(Float32Array, l),
_12935: l => arrayFromDartList(Float64Array, l),
_12936: (data, length) => {
          const view = new DataView(new ArrayBuffer(length));
          for (let i = 0; i < length; i++) {
              view.setUint8(i, dartInstance.exports.$byteDataGetUint8(data, i));
          }
          return view;
        },
_12937: l => arrayFromDartList(Array, l),
_12938: stringFromDartString,
_12939: stringToDartString,
_12940: () => ({}),
_12941: () => [],
_12942: l => new Array(l),
_12946: (o, p) => o[p],
_12947: (o, p, v) => o[p] = v,
_12948: (o, m, a) => o[m].apply(o, a),
_12950: o => String(o),
_12955: x0 => x0.index,
_12957: x0 => x0.length,
_12959: (x0,x1) => x0[x1],
_12963: x0 => x0.flags,
_12964: x0 => x0.multiline,
_12965: x0 => x0.ignoreCase,
_12966: x0 => x0.unicode,
_12967: x0 => x0.dotAll,
_12968: (x0,x1) => x0.lastIndex = x1
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

