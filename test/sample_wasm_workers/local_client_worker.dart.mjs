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

_56: (x0,x1) => x0.postMessage(x1),
_59: () => new MessageChannel(),
_60: f => finalizeWrapper(f,x0 => dartInstance.exports._60(f,x0)),
_61: x0 => x0.close(),
_62: x0 => x0.close(),
_63: () => new MessageChannel(),
_64: f => finalizeWrapper(f,x0 => dartInstance.exports._64(f,x0)),
_65: x0 => x0.close(),
_81: () => globalThis.self,
_83: () => globalThis.self,
_84: () => new MessageChannel(),
_85: x0 => x0.close(),
_86: x0 => x0.close(),
_87: x0 => x0.close(),
_88: f => finalizeWrapper(f,x0 => dartInstance.exports._88(f,x0)),
_89: f => finalizeWrapper(f,x0 => dartInstance.exports._89(f,x0)),
_2131: () => globalThis.window,
_2769: x0 => x0.data,
_2796: x0 => x0.port1,
_2797: x0 => x0.port2,
_2800: (x0,x1) => x0.onmessage = x1,
_2856: (x0,x1) => x0.onmessage = x1,
_18162: v => stringToDartString(v.toString()),
_18173: Date.now,
_18175: s => new Date(s * 1000).getTimezoneOffset() * 60 ,
_18177: () => {
          let stackString = new Error().stack.toString();
          let frames = stackString.split('\n');
          let drop = 2;
          if (frames[0] === 'Error') {
              drop += 1;
          }
          return frames.slice(drop).join('\n');
        },
_18186: s => stringToDartString(JSON.stringify(stringFromDartString(s))),
_18187: s => printToConsole(stringFromDartString(s)),
_18200: o => Object.keys(o),
_18205: (c) =>
              queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
_18207: (a, i) => a.push(i),
_18218: a => a.length,
_18220: (a, i) => a[i],
_18221: (a, i, v) => a[i] = v,
_18223: a => a.join(''),
_18224: (o, a, b) => o.replace(a, b),
_18226: (s, t) => s.split(t),
_18233: (s, p, i) => s.indexOf(p, i),
_18236: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
_18237: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
_18238: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
_18239: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
_18240: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
_18241: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
_18242: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
_18245: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
_18246: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
_18250: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
_18254: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
_18255: (b, o) => new DataView(b, o),
_18257: Function.prototype.call.bind(DataView.prototype.getUint8),
_18258: Function.prototype.call.bind(DataView.prototype.setUint8),
_18259: Function.prototype.call.bind(DataView.prototype.getInt8),
_18260: Function.prototype.call.bind(DataView.prototype.setInt8),
_18261: Function.prototype.call.bind(DataView.prototype.getUint16),
_18262: Function.prototype.call.bind(DataView.prototype.setUint16),
_18263: Function.prototype.call.bind(DataView.prototype.getInt16),
_18264: Function.prototype.call.bind(DataView.prototype.setInt16),
_18265: Function.prototype.call.bind(DataView.prototype.getUint32),
_18266: Function.prototype.call.bind(DataView.prototype.setUint32),
_18267: Function.prototype.call.bind(DataView.prototype.getInt32),
_18268: Function.prototype.call.bind(DataView.prototype.setInt32),
_18273: Function.prototype.call.bind(DataView.prototype.getFloat32),
_18275: Function.prototype.call.bind(DataView.prototype.getFloat64),
_18285: (s, m) => {
          try {
            return new RegExp(s, m);
          } catch (e) {
            return String(e);
          }
        },
_18288: (x0,x1) => x0.exec(x1),
_18289: (x0,x1) => x0.exec(x1),
_18290: x0 => x0.pop(),
_18296: o => o === undefined,
_18297: o => typeof o === 'boolean',
_18298: o => typeof o === 'number',
_18300: o => typeof o === 'string',
_18303: o => o instanceof Int8Array,
_18304: o => o instanceof Uint8Array,
_18305: o => o instanceof Uint8ClampedArray,
_18306: o => o instanceof Int16Array,
_18307: o => o instanceof Uint16Array,
_18308: o => o instanceof Int32Array,
_18309: o => o instanceof Uint32Array,
_18310: o => o instanceof Float32Array,
_18311: o => o instanceof Float64Array,
_18312: o => o instanceof ArrayBuffer,
_18313: o => o instanceof DataView,
_18314: o => o instanceof Array,
_18315: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
_18317: o => {
            const proto = Object.getPrototypeOf(o);
            return proto === Object.prototype || proto === null;
          },
_18318: o => o instanceof RegExp,
_18319: (l, r) => l === r,
_18320: o => o,
_18321: o => o,
_18322: o => o,
_18323: b => !!b,
_18324: o => o.length,
_18327: (o, i) => o[i],
_18328: f => f.dartFunction,
_18329: l => arrayFromDartList(Int8Array, l),
_18330: l => arrayFromDartList(Uint8Array, l),
_18331: l => arrayFromDartList(Uint8ClampedArray, l),
_18332: l => arrayFromDartList(Int16Array, l),
_18333: l => arrayFromDartList(Uint16Array, l),
_18334: l => arrayFromDartList(Int32Array, l),
_18335: l => arrayFromDartList(Uint32Array, l),
_18336: l => arrayFromDartList(Float32Array, l),
_18337: l => arrayFromDartList(Float64Array, l),
_18338: (data, length) => {
          const view = new DataView(new ArrayBuffer(length));
          for (let i = 0; i < length; i++) {
              view.setUint8(i, dartInstance.exports.$byteDataGetUint8(data, i));
          }
          return view;
        },
_18339: l => arrayFromDartList(Array, l),
_18340: stringFromDartString,
_18341: stringToDartString,
_18342: () => ({}),
_18343: () => [],
_18344: l => new Array(l),
_18348: (o, p) => o[p],
_18349: (o, p, v) => o[p] = v,
_18350: (o, m, a) => o[m].apply(o, a),
_18352: o => String(o),
_18357: x0 => x0.index,
_18359: x0 => x0.length,
_18361: (x0,x1) => x0[x1],
_18365: x0 => x0.flags,
_18366: x0 => x0.multiline,
_18367: x0 => x0.ignoreCase,
_18368: x0 => x0.unicode,
_18369: x0 => x0.dotAll,
_18370: (x0,x1) => x0.lastIndex = x1
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

