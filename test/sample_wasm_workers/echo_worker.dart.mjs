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
_2729: x0 => x0.data,
_2817: (x0,x1) => x0.onmessage = x1,
_18124: v => stringToDartString(v.toString()),
_18139: () => {
          let stackString = new Error().stack.toString();
          let frames = stackString.split('\n');
          let drop = 2;
          if (frames[0] === 'Error') {
              drop += 1;
          }
          return frames.slice(drop).join('\n');
        },
_18148: s => stringToDartString(JSON.stringify(stringFromDartString(s))),
_18149: s => printToConsole(stringFromDartString(s)),
_18162: o => Object.keys(o),
_18167: (c) =>
              queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
_18169: (a, i) => a.push(i),
_18180: a => a.length,
_18182: (a, i) => a[i],
_18183: (a, i, v) => a[i] = v,
_18185: a => a.join(''),
_18195: (s, p, i) => s.indexOf(p, i),
_18198: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
_18199: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
_18200: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
_18201: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
_18202: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
_18203: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
_18204: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
_18207: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
_18208: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
_18212: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
_18216: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
_18217: (b, o) => new DataView(b, o),
_18219: Function.prototype.call.bind(DataView.prototype.getUint8),
_18221: Function.prototype.call.bind(DataView.prototype.getInt8),
_18223: Function.prototype.call.bind(DataView.prototype.getUint16),
_18225: Function.prototype.call.bind(DataView.prototype.getInt16),
_18227: Function.prototype.call.bind(DataView.prototype.getUint32),
_18229: Function.prototype.call.bind(DataView.prototype.getInt32),
_18235: Function.prototype.call.bind(DataView.prototype.getFloat32),
_18237: Function.prototype.call.bind(DataView.prototype.getFloat64),
_18258: o => o === undefined,
_18259: o => typeof o === 'boolean',
_18260: o => typeof o === 'number',
_18262: o => typeof o === 'string',
_18265: o => o instanceof Int8Array,
_18266: o => o instanceof Uint8Array,
_18267: o => o instanceof Uint8ClampedArray,
_18268: o => o instanceof Int16Array,
_18269: o => o instanceof Uint16Array,
_18270: o => o instanceof Int32Array,
_18271: o => o instanceof Uint32Array,
_18272: o => o instanceof Float32Array,
_18273: o => o instanceof Float64Array,
_18274: o => o instanceof ArrayBuffer,
_18275: o => o instanceof DataView,
_18276: o => o instanceof Array,
_18277: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
_18279: o => {
            const proto = Object.getPrototypeOf(o);
            return proto === Object.prototype || proto === null;
          },
_18281: (l, r) => l === r,
_18282: o => o,
_18283: o => o,
_18284: o => o,
_18285: b => !!b,
_18286: o => o.length,
_18289: (o, i) => o[i],
_18290: f => f.dartFunction,
_18291: l => arrayFromDartList(Int8Array, l),
_18292: l => arrayFromDartList(Uint8Array, l),
_18293: l => arrayFromDartList(Uint8ClampedArray, l),
_18294: l => arrayFromDartList(Int16Array, l),
_18295: l => arrayFromDartList(Uint16Array, l),
_18296: l => arrayFromDartList(Int32Array, l),
_18297: l => arrayFromDartList(Uint32Array, l),
_18298: l => arrayFromDartList(Float32Array, l),
_18299: l => arrayFromDartList(Float64Array, l),
_18300: (data, length) => {
          const view = new DataView(new ArrayBuffer(length));
          for (let i = 0; i < length; i++) {
              view.setUint8(i, dartInstance.exports.$byteDataGetUint8(data, i));
          }
          return view;
        },
_18301: l => arrayFromDartList(Array, l),
_18302: stringFromDartString,
_18303: stringToDartString,
_18304: () => ({}),
_18305: () => [],
_18306: l => new Array(l),
_18310: (o, p) => o[p],
_18311: (o, p, v) => o[p] = v,
_18312: (o, m, a) => o[m].apply(o, a),
_18314: o => String(o)
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

