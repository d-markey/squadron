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
_76: () => globalThis.self,
_77: () => new MessageChannel(),
_78: x0 => x0.close(),
_79: x0 => x0.close(),
_80: x0 => x0.close(),
_81: f => finalizeWrapper(f,x0 => dartInstance.exports._81(f,x0)),
_82: f => finalizeWrapper(f,x0 => dartInstance.exports._82(f,x0)),
_2762: x0 => x0.data,
_2789: x0 => x0.port1,
_2790: x0 => x0.port2,
_2793: (x0,x1) => x0.onmessage = x1,
_2849: (x0,x1) => x0.onmessage = x1,
_18155: v => stringToDartString(v.toString()),
_18166: Date.now,
_18168: s => new Date(s * 1000).getTimezoneOffset() * 60 ,
_18170: () => {
          let stackString = new Error().stack.toString();
          let frames = stackString.split('\n');
          let drop = 2;
          if (frames[0] === 'Error') {
              drop += 1;
          }
          return frames.slice(drop).join('\n');
        },
_18179: s => stringToDartString(JSON.stringify(stringFromDartString(s))),
_18180: s => printToConsole(stringFromDartString(s)),
_18193: o => Object.keys(o),
_18198: (c) =>
              queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
_18200: (a, i) => a.push(i),
_18211: a => a.length,
_18213: (a, i) => a[i],
_18214: (a, i, v) => a[i] = v,
_18216: a => a.join(''),
_18226: (s, p, i) => s.indexOf(p, i),
_18229: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
_18230: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
_18231: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
_18232: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
_18233: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
_18234: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
_18235: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
_18238: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
_18239: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
_18243: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
_18247: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
_18248: (b, o) => new DataView(b, o),
_18250: Function.prototype.call.bind(DataView.prototype.getUint8),
_18251: Function.prototype.call.bind(DataView.prototype.setUint8),
_18252: Function.prototype.call.bind(DataView.prototype.getInt8),
_18253: Function.prototype.call.bind(DataView.prototype.setInt8),
_18254: Function.prototype.call.bind(DataView.prototype.getUint16),
_18255: Function.prototype.call.bind(DataView.prototype.setUint16),
_18256: Function.prototype.call.bind(DataView.prototype.getInt16),
_18257: Function.prototype.call.bind(DataView.prototype.setInt16),
_18258: Function.prototype.call.bind(DataView.prototype.getUint32),
_18259: Function.prototype.call.bind(DataView.prototype.setUint32),
_18260: Function.prototype.call.bind(DataView.prototype.getInt32),
_18261: Function.prototype.call.bind(DataView.prototype.setInt32),
_18266: Function.prototype.call.bind(DataView.prototype.getFloat32),
_18268: Function.prototype.call.bind(DataView.prototype.getFloat64),
_18289: o => o === undefined,
_18290: o => typeof o === 'boolean',
_18291: o => typeof o === 'number',
_18293: o => typeof o === 'string',
_18296: o => o instanceof Int8Array,
_18297: o => o instanceof Uint8Array,
_18298: o => o instanceof Uint8ClampedArray,
_18299: o => o instanceof Int16Array,
_18300: o => o instanceof Uint16Array,
_18301: o => o instanceof Int32Array,
_18302: o => o instanceof Uint32Array,
_18303: o => o instanceof Float32Array,
_18304: o => o instanceof Float64Array,
_18305: o => o instanceof ArrayBuffer,
_18306: o => o instanceof DataView,
_18307: o => o instanceof Array,
_18308: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
_18310: o => {
            const proto = Object.getPrototypeOf(o);
            return proto === Object.prototype || proto === null;
          },
_18312: (l, r) => l === r,
_18313: o => o,
_18314: o => o,
_18315: o => o,
_18316: b => !!b,
_18317: o => o.length,
_18320: (o, i) => o[i],
_18321: f => f.dartFunction,
_18322: l => arrayFromDartList(Int8Array, l),
_18323: l => arrayFromDartList(Uint8Array, l),
_18324: l => arrayFromDartList(Uint8ClampedArray, l),
_18325: l => arrayFromDartList(Int16Array, l),
_18326: l => arrayFromDartList(Uint16Array, l),
_18327: l => arrayFromDartList(Int32Array, l),
_18328: l => arrayFromDartList(Uint32Array, l),
_18329: l => arrayFromDartList(Float32Array, l),
_18330: l => arrayFromDartList(Float64Array, l),
_18331: (data, length) => {
          const view = new DataView(new ArrayBuffer(length));
          for (let i = 0; i < length; i++) {
              view.setUint8(i, dartInstance.exports.$byteDataGetUint8(data, i));
          }
          return view;
        },
_18332: l => arrayFromDartList(Array, l),
_18333: stringFromDartString,
_18334: stringToDartString,
_18335: () => ({}),
_18336: () => [],
_18337: l => new Array(l),
_18341: (o, p) => o[p],
_18342: (o, p, v) => o[p] = v,
_18343: (o, m, a) => o[m].apply(o, a),
_18345: o => String(o)
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

