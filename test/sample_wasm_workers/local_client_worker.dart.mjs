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

_57: (x0,x1) => x0.postMessage(x1),
_60: () => new MessageChannel(),
_61: f => finalizeWrapper(f,x0 => dartInstance.exports._61(f,x0)),
_62: x0 => x0.close(),
_63: x0 => x0.close(),
_64: () => new MessageChannel(),
_65: f => finalizeWrapper(f,x0 => dartInstance.exports._65(f,x0)),
_66: x0 => x0.close(),
_82: () => globalThis.self,
_84: () => globalThis.self,
_85: () => new MessageChannel(),
_86: x0 => x0.close(),
_87: x0 => x0.close(),
_88: x0 => x0.close(),
_89: f => finalizeWrapper(f,x0 => dartInstance.exports._89(f,x0)),
_90: f => finalizeWrapper(f,x0 => dartInstance.exports._90(f,x0)),
_2132: () => globalThis.window,
_2770: x0 => x0.data,
_2797: x0 => x0.port1,
_2798: x0 => x0.port2,
_2801: (x0,x1) => x0.onmessage = x1,
_2857: (x0,x1) => x0.onmessage = x1,
_18163: v => stringToDartString(v.toString()),
_18174: Date.now,
_18176: s => new Date(s * 1000).getTimezoneOffset() * 60 ,
_18178: () => {
          let stackString = new Error().stack.toString();
          let frames = stackString.split('\n');
          let drop = 2;
          if (frames[0] === 'Error') {
              drop += 1;
          }
          return frames.slice(drop).join('\n');
        },
_18187: s => stringToDartString(JSON.stringify(stringFromDartString(s))),
_18188: s => printToConsole(stringFromDartString(s)),
_18201: o => Object.keys(o),
_18206: (c) =>
              queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
_18208: (a, i) => a.push(i),
_18219: a => a.length,
_18221: (a, i) => a[i],
_18222: (a, i, v) => a[i] = v,
_18224: a => a.join(''),
_18225: (o, a, b) => o.replace(a, b),
_18227: (s, t) => s.split(t),
_18234: (s, p, i) => s.indexOf(p, i),
_18237: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
_18238: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
_18239: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
_18240: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
_18241: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
_18242: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
_18243: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
_18246: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
_18247: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
_18251: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
_18255: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
_18256: (b, o) => new DataView(b, o),
_18258: Function.prototype.call.bind(DataView.prototype.getUint8),
_18259: Function.prototype.call.bind(DataView.prototype.setUint8),
_18260: Function.prototype.call.bind(DataView.prototype.getInt8),
_18261: Function.prototype.call.bind(DataView.prototype.setInt8),
_18262: Function.prototype.call.bind(DataView.prototype.getUint16),
_18263: Function.prototype.call.bind(DataView.prototype.setUint16),
_18264: Function.prototype.call.bind(DataView.prototype.getInt16),
_18265: Function.prototype.call.bind(DataView.prototype.setInt16),
_18266: Function.prototype.call.bind(DataView.prototype.getUint32),
_18267: Function.prototype.call.bind(DataView.prototype.setUint32),
_18268: Function.prototype.call.bind(DataView.prototype.getInt32),
_18269: Function.prototype.call.bind(DataView.prototype.setInt32),
_18274: Function.prototype.call.bind(DataView.prototype.getFloat32),
_18276: Function.prototype.call.bind(DataView.prototype.getFloat64),
_18286: (s, m) => {
          try {
            return new RegExp(s, m);
          } catch (e) {
            return String(e);
          }
        },
_18289: (x0,x1) => x0.exec(x1),
_18290: (x0,x1) => x0.exec(x1),
_18291: x0 => x0.pop(),
_18297: o => o === undefined,
_18298: o => typeof o === 'boolean',
_18299: o => typeof o === 'number',
_18301: o => typeof o === 'string',
_18304: o => o instanceof Int8Array,
_18305: o => o instanceof Uint8Array,
_18306: o => o instanceof Uint8ClampedArray,
_18307: o => o instanceof Int16Array,
_18308: o => o instanceof Uint16Array,
_18309: o => o instanceof Int32Array,
_18310: o => o instanceof Uint32Array,
_18311: o => o instanceof Float32Array,
_18312: o => o instanceof Float64Array,
_18313: o => o instanceof ArrayBuffer,
_18314: o => o instanceof DataView,
_18315: o => o instanceof Array,
_18316: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
_18318: o => {
            const proto = Object.getPrototypeOf(o);
            return proto === Object.prototype || proto === null;
          },
_18319: o => o instanceof RegExp,
_18320: (l, r) => l === r,
_18321: o => o,
_18322: o => o,
_18323: o => o,
_18324: b => !!b,
_18325: o => o.length,
_18328: (o, i) => o[i],
_18329: f => f.dartFunction,
_18330: l => arrayFromDartList(Int8Array, l),
_18331: l => arrayFromDartList(Uint8Array, l),
_18332: l => arrayFromDartList(Uint8ClampedArray, l),
_18333: l => arrayFromDartList(Int16Array, l),
_18334: l => arrayFromDartList(Uint16Array, l),
_18335: l => arrayFromDartList(Int32Array, l),
_18336: l => arrayFromDartList(Uint32Array, l),
_18337: l => arrayFromDartList(Float32Array, l),
_18338: l => arrayFromDartList(Float64Array, l),
_18339: (data, length) => {
          const view = new DataView(new ArrayBuffer(length));
          for (let i = 0; i < length; i++) {
              view.setUint8(i, dartInstance.exports.$byteDataGetUint8(data, i));
          }
          return view;
        },
_18340: l => arrayFromDartList(Array, l),
_18341: stringFromDartString,
_18342: stringToDartString,
_18343: () => ({}),
_18344: () => [],
_18345: l => new Array(l),
_18349: (o, p) => o[p],
_18350: (o, p, v) => o[p] = v,
_18351: (o, m, a) => o[m].apply(o, a),
_18353: o => String(o),
_18358: x0 => x0.index,
_18360: x0 => x0.length,
_18362: (x0,x1) => x0[x1],
_18366: x0 => x0.flags,
_18367: x0 => x0.multiline,
_18368: x0 => x0.ignoreCase,
_18369: x0 => x0.unicode,
_18370: x0 => x0.dotAll,
_18371: (x0,x1) => x0.lastIndex = x1
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

