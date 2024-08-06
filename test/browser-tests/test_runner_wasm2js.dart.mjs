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

_11: x0 => new Array(x0),
_14: (o, c) => o instanceof c,
_45: () => new XMLHttpRequest(),
_46: (x0,x1,x2,x3) => x0.open(x1,x2,x3),
_47: (x0,x1,x2) => x0.setRequestHeader(x1,x2),
_48: (x0,x1) => x0.send(x1),
_49: x0 => x0.abort(),
_50: x0 => x0.getAllResponseHeaders(),
_51: () => new MessageChannel(),
_52: (x0,x1) => x0.postMessage(x1),
_53: (x0,x1,x2) => x0.postMessage(x1,x2),
_54: x0 => x0.close(),
_55: x0 => x0.close(),
_56: f => finalizeWrapper(f,x0 => dartInstance.exports._56(f,x0)),
_57: f => finalizeWrapper(f,x0 => dartInstance.exports._57(f,x0)),
_58: () => new MessageChannel(),
_59: () => new MessageChannel(),
_60: f => finalizeWrapper(f,x0 => dartInstance.exports._60(f,x0)),
_61: x0 => x0.close(),
_62: () => new MessageChannel(),
_63: x0 => new Worker(x0),
_64: f => finalizeWrapper(f,x0 => dartInstance.exports._64(f,x0)),
_65: f => finalizeWrapper(f,x0 => dartInstance.exports._65(f,x0)),
_66: f => finalizeWrapper(f,x0 => dartInstance.exports._66(f,x0)),
_67: (x0,x1) => x0.postMessage(x1),
_68: (x0,x1,x2) => x0.postMessage(x1,x2),
_69: x0 => x0.close(),
_70: x0 => x0.close(),
_71: x0 => x0.terminate(),
_72: f => finalizeWrapper(f,x0 => dartInstance.exports._72(f,x0)),
_73: x0 => x0.close(),
_74: x0 => x0.close(),
_75: () => new MessageChannel(),
_84: (x0,x1,x2) => x0.postMessage(x1,x2),
_86: x0 => globalThis.dartPrint = x0,
_87: (x0,x1) => x0.querySelector(x1),
_88: f => finalizeWrapper(f,x0 => dartInstance.exports._88(f,x0)),
_89: f => finalizeWrapper(f,x0 => dartInstance.exports._89(f,x0)),
_90: f => finalizeWrapper(f,x0 => dartInstance.exports._90(f,x0)),
_91: x0 => x0.terminate(),
_92: f => finalizeWrapper(f,x0 => dartInstance.exports._92(f,x0)),
_93: f => finalizeWrapper(f,x0 => dartInstance.exports._93(f,x0)),
_94: x0 => x0.terminate(),
_95: f => finalizeWrapper(f,x0 => dartInstance.exports._95(f,x0)),
_96: f => finalizeWrapper(f,x0 => dartInstance.exports._96(f,x0)),
_97: x0 => x0.terminate(),
_98: f => finalizeWrapper(f,x0 => dartInstance.exports._98(f,x0)),
_99: f => finalizeWrapper(f,x0 => dartInstance.exports._99(f,x0)),
_100: x0 => x0.terminate(),
_101: f => finalizeWrapper(f,x0 => dartInstance.exports._101(f,x0)),
_102: f => finalizeWrapper(f,x0 => dartInstance.exports._102(f,x0)),
_103: x0 => x0.terminate(),
_104: (x0,x1) => x0.error(x1),
_105: (x0,x1) => x0.querySelectorAll(x1),
_106: (x0,x1) => x0.item(x1),
_107: (x0,x1) => x0.getNamedItem(x1),
_108: x0 => globalThis.URL.revokeObjectURL(x0),
_109: x0 => ({type: x0}),
_110: (x0,x1) => new Blob(x0,x1),
_111: x0 => globalThis.URL.createObjectURL(x0),
_116: (x0,x1) => x0.createElement(x1),
_119: f => finalizeWrapper(f,x0 => dartInstance.exports._119(f,x0)),
_120: f => finalizeWrapper(f,x0 => dartInstance.exports._120(f,x0)),
_121: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
_122: (x0,x1,x2,x3) => x0.removeEventListener(x1,x2,x3),
_140: f => finalizeWrapper(f,x0 => dartInstance.exports._140(f,x0)),
_141: (x0,x1) => x0.log(x1),
_144: (x0,x1) => x0.appendChild(x1),
_145: (x0,x1,x2) => x0.scrollTo(x1,x2),
_180: (x0,x1) => x0.withCredentials = x1,
_182: x0 => x0.responseURL,
_183: x0 => x0.status,
_184: x0 => x0.statusText,
_186: (x0,x1) => x0.responseType = x1,
_187: x0 => x0.response,
_394: (x0,x1) => x0.onscroll = x1,
_2003: () => globalThis.window,
_2064: x0 => x0.location,
_2081: x0 => x0.parent,
_2083: x0 => x0.navigator,
_2338: x0 => x0.href,
_2340: x0 => x0.origin,
_2389: x0 => x0.message,
_2390: x0 => x0.filename,
_2391: x0 => x0.lineno,
_2456: x0 => x0.userAgent,
_2507: x0 => x0.data,
_2542: x0 => x0.port1,
_2543: x0 => x0.port2,
_2548: (x0,x1) => x0.onmessage = x1,
_2550: (x0,x1) => x0.onmessageerror = x1,
_2621: (x0,x1) => x0.onmessage = x1,
_2623: (x0,x1) => x0.onmessageerror = x1,
_2624: x0 => x0.onerror,
_2625: (x0,x1) => x0.onerror = x1,
_5712: x0 => x0.length,
_5798: () => globalThis.document,
_6234: x0 => x0.scrollTop,
_6239: x0 => x0.scrollHeight,
_6243: x0 => x0.clientHeight,
_6255: x0 => x0.attributes,
_6262: (x0,x1) => x0.innerHTML = x1,
_6263: x0 => x0.outerHTML,
_6378: x0 => x0.value,
_12948: () => globalThis.console,
_12977: v => stringToDartString(v.toString()),
_12988: Date.now,
_12990: s => new Date(s * 1000).getTimezoneOffset() * 60 ,
_12992: () => {
          let stackString = new Error().stack.toString();
          let frames = stackString.split('\n');
          let drop = 2;
          if (frames[0] === 'Error') {
              drop += 1;
          }
          return frames.slice(drop).join('\n');
        },
_12993: () => typeof dartUseDateNowForTicks !== "undefined",
_12994: () => 1000 * performance.now(),
_12995: () => Date.now(),
_12996: () => {
      // On browsers return `globalThis.location.href`
      if (globalThis.location != null) {
        return stringToDartString(globalThis.location.href);
      }
      return null;
    },
_12997: () => {
        return typeof process != undefined &&
               Object.prototype.toString.call(process) == "[object process]" &&
               process.platform == "win32"
      },
_13001: s => stringToDartString(JSON.stringify(stringFromDartString(s))),
_13002: s => printToConsole(stringFromDartString(s)),
_13015: o => Object.keys(o),
_13016: (ms, c) =>
              setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
_13017: (handle) => clearTimeout(handle),
_13018: (ms, c) =>
          setInterval(() => dartInstance.exports.$invokeCallback(c), ms),
_13019: (handle) => clearInterval(handle),
_13020: (c) =>
              queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
_13021: () => Date.now(),
_13022: (a, i) => a.push(i),
_13025: (a, l) => a.length = l,
_13029: (a, s) => a.join(s),
_13032: (a, b) => a == b ? 0 : (a > b ? 1 : -1),
_13033: a => a.length,
_13035: (a, i) => a[i],
_13036: (a, i, v) => a[i] = v,
_13038: a => a.join(''),
_13039: (o, a, b) => o.replace(a, b),
_13041: (s, t) => s.split(t),
_13042: s => s.toLowerCase(),
_13043: s => s.toUpperCase(),
_13044: s => s.trim(),
_13046: s => s.trimRight(),
_13048: (s, p, i) => s.indexOf(p, i),
_13049: (s, p, i) => s.lastIndexOf(p, i),
_13051: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
_13052: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
_13053: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
_13054: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
_13055: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
_13056: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
_13057: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
_13060: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
_13061: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
_13062: Object.is,
_13065: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
_13067: o => o.buffer,
_13068: o => o.byteOffset,
_13069: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
_13070: (b, o) => new DataView(b, o),
_13072: Function.prototype.call.bind(DataView.prototype.getUint8),
_13073: Function.prototype.call.bind(DataView.prototype.setUint8),
_13074: Function.prototype.call.bind(DataView.prototype.getInt8),
_13075: Function.prototype.call.bind(DataView.prototype.setInt8),
_13076: Function.prototype.call.bind(DataView.prototype.getUint16),
_13077: Function.prototype.call.bind(DataView.prototype.setUint16),
_13078: Function.prototype.call.bind(DataView.prototype.getInt16),
_13079: Function.prototype.call.bind(DataView.prototype.setInt16),
_13080: Function.prototype.call.bind(DataView.prototype.getUint32),
_13081: Function.prototype.call.bind(DataView.prototype.setUint32),
_13082: Function.prototype.call.bind(DataView.prototype.getInt32),
_13083: Function.prototype.call.bind(DataView.prototype.setInt32),
_13088: Function.prototype.call.bind(DataView.prototype.getFloat32),
_13089: Function.prototype.call.bind(DataView.prototype.setFloat32),
_13090: Function.prototype.call.bind(DataView.prototype.getFloat64),
_13091: Function.prototype.call.bind(DataView.prototype.setFloat64),
_13097: s => stringToDartString(stringFromDartString(s).toUpperCase()),
_13098: s => stringToDartString(stringFromDartString(s).toLowerCase()),
_13100: (s, m) => {
          try {
            return new RegExp(s, m);
          } catch (e) {
            return String(e);
          }
        },
_13101: (x0,x1) => x0.exec(x1),
_13102: (x0,x1) => x0.test(x1),
_13103: (x0,x1) => x0.exec(x1),
_13104: (x0,x1) => x0.exec(x1),
_13105: x0 => x0.pop(),
_13109: (x0,x1,x2) => x0[x1] = x2,
_13111: o => o === undefined,
_13112: o => typeof o === 'boolean',
_13113: o => typeof o === 'number',
_13115: o => typeof o === 'string',
_13118: o => o instanceof Int8Array,
_13119: o => o instanceof Uint8Array,
_13120: o => o instanceof Uint8ClampedArray,
_13121: o => o instanceof Int16Array,
_13122: o => o instanceof Uint16Array,
_13123: o => o instanceof Int32Array,
_13124: o => o instanceof Uint32Array,
_13125: o => o instanceof Float32Array,
_13126: o => o instanceof Float64Array,
_13127: o => o instanceof ArrayBuffer,
_13128: o => o instanceof DataView,
_13129: o => o instanceof Array,
_13130: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
_13132: o => {
            const proto = Object.getPrototypeOf(o);
            return proto === Object.prototype || proto === null;
          },
_13133: o => o instanceof RegExp,
_13134: (l, r) => l === r,
_13135: o => o,
_13136: o => o,
_13137: o => o,
_13138: b => !!b,
_13139: o => o.length,
_13142: (o, i) => o[i],
_13143: f => f.dartFunction,
_13144: l => arrayFromDartList(Int8Array, l),
_13145: l => arrayFromDartList(Uint8Array, l),
_13146: l => arrayFromDartList(Uint8ClampedArray, l),
_13147: l => arrayFromDartList(Int16Array, l),
_13148: l => arrayFromDartList(Uint16Array, l),
_13149: l => arrayFromDartList(Int32Array, l),
_13150: l => arrayFromDartList(Uint32Array, l),
_13151: l => arrayFromDartList(Float32Array, l),
_13152: l => arrayFromDartList(Float64Array, l),
_13153: (data, length) => {
          const view = new DataView(new ArrayBuffer(length));
          for (let i = 0; i < length; i++) {
              view.setUint8(i, dartInstance.exports.$byteDataGetUint8(data, i));
          }
          return view;
        },
_13154: l => arrayFromDartList(Array, l),
_13155: stringFromDartString,
_13156: stringToDartString,
_13157: () => ({}),
_13158: () => [],
_13159: l => new Array(l),
_13160: () => globalThis,
_13163: (o, p) => o[p],
_13164: (o, p, v) => o[p] = v,
_13165: (o, m, a) => o[m].apply(o, a),
_13167: o => String(o),
_13169: s => {
      let jsString = stringFromDartString(s);
      if (/[[\]{}()*+?.\\^$|]/.test(jsString)) {
          jsString = jsString.replace(/[[\]{}()*+?.\\^$|]/g, '\\$&');
      }
      return stringToDartString(jsString);
    },
_13172: x0 => x0.index,
_13174: x0 => x0.length,
_13176: (x0,x1) => x0[x1],
_13178: (x0,x1) => x0.exec(x1),
_13180: x0 => x0.flags,
_13181: x0 => x0.multiline,
_13182: x0 => x0.ignoreCase,
_13183: x0 => x0.unicode,
_13184: x0 => x0.dotAll,
_13185: (x0,x1) => x0.lastIndex = x1,
_13186: (o, p) => p in o,
_13187: (o, p) => o[p],
_13188: (o, p, v) => o[p] = v
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

