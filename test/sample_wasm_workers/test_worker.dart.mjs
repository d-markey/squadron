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
_78: () => globalThis.self,
_79: () => new MessageChannel(),
_80: x0 => x0.close(),
_81: x0 => x0.close(),
_82: x0 => x0.close(),
_83: f => finalizeWrapper(f,x0 => dartInstance.exports._83(f,x0)),
_84: f => finalizeWrapper(f,x0 => dartInstance.exports._84(f,x0)),
_2764: x0 => x0.data,
_2791: x0 => x0.port1,
_2792: x0 => x0.port2,
_2795: (x0,x1) => x0.onmessage = x1,
_2851: (x0,x1) => x0.onmessage = x1,
_18157: v => stringToDartString(v.toString()),
_18168: Date.now,
_18170: s => new Date(s * 1000).getTimezoneOffset() * 60 ,
_18172: () => {
          let stackString = new Error().stack.toString();
          let frames = stackString.split('\n');
          let drop = 2;
          if (frames[0] === 'Error') {
              drop += 1;
          }
          return frames.slice(drop).join('\n');
        },
_18173: () => typeof dartUseDateNowForTicks !== "undefined",
_18174: () => 1000 * performance.now(),
_18175: () => Date.now(),
_18181: s => stringToDartString(JSON.stringify(stringFromDartString(s))),
_18182: s => printToConsole(stringFromDartString(s)),
_18195: o => Object.keys(o),
_18196: (ms, c) =>
              setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
_18200: (c) =>
              queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
_18202: (a, i) => a.push(i),
_18213: a => a.length,
_18215: (a, i) => a[i],
_18216: (a, i, v) => a[i] = v,
_18218: a => a.join(''),
_18224: s => s.trim(),
_18228: (s, p, i) => s.indexOf(p, i),
_18231: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
_18232: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
_18233: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
_18234: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
_18235: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
_18236: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
_18237: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
_18240: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
_18241: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
_18245: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
_18249: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
_18250: (b, o) => new DataView(b, o),
_18252: Function.prototype.call.bind(DataView.prototype.getUint8),
_18253: Function.prototype.call.bind(DataView.prototype.setUint8),
_18254: Function.prototype.call.bind(DataView.prototype.getInt8),
_18255: Function.prototype.call.bind(DataView.prototype.setInt8),
_18256: Function.prototype.call.bind(DataView.prototype.getUint16),
_18257: Function.prototype.call.bind(DataView.prototype.setUint16),
_18258: Function.prototype.call.bind(DataView.prototype.getInt16),
_18259: Function.prototype.call.bind(DataView.prototype.setInt16),
_18260: Function.prototype.call.bind(DataView.prototype.getUint32),
_18261: Function.prototype.call.bind(DataView.prototype.setUint32),
_18262: Function.prototype.call.bind(DataView.prototype.getInt32),
_18263: Function.prototype.call.bind(DataView.prototype.setInt32),
_18268: Function.prototype.call.bind(DataView.prototype.getFloat32),
_18270: Function.prototype.call.bind(DataView.prototype.getFloat64),
_18280: (s, m) => {
          try {
            return new RegExp(s, m);
          } catch (e) {
            return String(e);
          }
        },
_18281: (x0,x1) => x0.exec(x1),
_18291: o => o === undefined,
_18292: o => typeof o === 'boolean',
_18293: o => typeof o === 'number',
_18295: o => typeof o === 'string',
_18298: o => o instanceof Int8Array,
_18299: o => o instanceof Uint8Array,
_18300: o => o instanceof Uint8ClampedArray,
_18301: o => o instanceof Int16Array,
_18302: o => o instanceof Uint16Array,
_18303: o => o instanceof Int32Array,
_18304: o => o instanceof Uint32Array,
_18305: o => o instanceof Float32Array,
_18306: o => o instanceof Float64Array,
_18307: o => o instanceof ArrayBuffer,
_18308: o => o instanceof DataView,
_18309: o => o instanceof Array,
_18310: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
_18312: o => {
            const proto = Object.getPrototypeOf(o);
            return proto === Object.prototype || proto === null;
          },
_18313: o => o instanceof RegExp,
_18314: (l, r) => l === r,
_18315: o => o,
_18316: o => o,
_18317: o => o,
_18318: b => !!b,
_18319: o => o.length,
_18322: (o, i) => o[i],
_18323: f => f.dartFunction,
_18324: l => arrayFromDartList(Int8Array, l),
_18325: l => arrayFromDartList(Uint8Array, l),
_18326: l => arrayFromDartList(Uint8ClampedArray, l),
_18327: l => arrayFromDartList(Int16Array, l),
_18328: l => arrayFromDartList(Uint16Array, l),
_18329: l => arrayFromDartList(Int32Array, l),
_18330: l => arrayFromDartList(Uint32Array, l),
_18331: l => arrayFromDartList(Float32Array, l),
_18332: l => arrayFromDartList(Float64Array, l),
_18333: (data, length) => {
          const view = new DataView(new ArrayBuffer(length));
          for (let i = 0; i < length; i++) {
              view.setUint8(i, dartInstance.exports.$byteDataGetUint8(data, i));
          }
          return view;
        },
_18334: l => arrayFromDartList(Array, l),
_18335: stringFromDartString,
_18336: stringToDartString,
_18337: () => ({}),
_18338: () => [],
_18339: l => new Array(l),
_18343: (o, p) => o[p],
_18344: (o, p, v) => o[p] = v,
_18345: (o, m, a) => o[m].apply(o, a),
_18347: o => String(o),
_18354: x0 => x0.length,
_18356: (x0,x1) => x0[x1],
_18360: x0 => x0.flags
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

