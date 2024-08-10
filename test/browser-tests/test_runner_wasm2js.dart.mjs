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
_108: () => globalThis.self,
_109: x0 => globalThis.URL.revokeObjectURL(x0),
_110: x0 => ({type: x0}),
_111: (x0,x1) => new Blob(x0,x1),
_112: x0 => globalThis.URL.createObjectURL(x0),
_117: (x0,x1) => x0.createElement(x1),
_120: f => finalizeWrapper(f,x0 => dartInstance.exports._120(f,x0)),
_121: f => finalizeWrapper(f,x0 => dartInstance.exports._121(f,x0)),
_122: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
_123: (x0,x1,x2,x3) => x0.removeEventListener(x1,x2,x3),
_141: f => finalizeWrapper(f,x0 => dartInstance.exports._141(f,x0)),
_142: (x0,x1) => x0.log(x1),
_145: (x0,x1) => x0.appendChild(x1),
_146: (x0,x1,x2) => x0.scrollTo(x1,x2),
_181: (x0,x1) => x0.withCredentials = x1,
_183: x0 => x0.responseURL,
_184: x0 => x0.status,
_185: x0 => x0.statusText,
_187: (x0,x1) => x0.responseType = x1,
_188: x0 => x0.response,
_395: (x0,x1) => x0.onscroll = x1,
_2004: () => globalThis.window,
_2065: x0 => x0.location,
_2082: x0 => x0.parent,
_2084: x0 => x0.navigator,
_2339: x0 => x0.href,
_2341: x0 => x0.origin,
_2390: x0 => x0.message,
_2391: x0 => x0.filename,
_2392: x0 => x0.lineno,
_2457: x0 => x0.userAgent,
_2508: x0 => x0.data,
_2543: x0 => x0.port1,
_2544: x0 => x0.port2,
_2549: (x0,x1) => x0.onmessage = x1,
_2551: (x0,x1) => x0.onmessageerror = x1,
_2622: (x0,x1) => x0.onmessage = x1,
_2624: (x0,x1) => x0.onmessageerror = x1,
_2625: x0 => x0.onerror,
_2626: (x0,x1) => x0.onerror = x1,
_5713: x0 => x0.length,
_5799: () => globalThis.document,
_6235: x0 => x0.scrollTop,
_6240: x0 => x0.scrollHeight,
_6244: x0 => x0.clientHeight,
_6256: x0 => x0.attributes,
_6263: (x0,x1) => x0.innerHTML = x1,
_6264: x0 => x0.outerHTML,
_6379: x0 => x0.value,
_12949: () => globalThis.console,
_12978: v => stringToDartString(v.toString()),
_12989: Date.now,
_12991: s => new Date(s * 1000).getTimezoneOffset() * 60 ,
_12993: () => {
          let stackString = new Error().stack.toString();
          let frames = stackString.split('\n');
          let drop = 2;
          if (frames[0] === 'Error') {
              drop += 1;
          }
          return frames.slice(drop).join('\n');
        },
_12994: () => typeof dartUseDateNowForTicks !== "undefined",
_12995: () => 1000 * performance.now(),
_12996: () => Date.now(),
_12997: () => {
      // On browsers return `globalThis.location.href`
      if (globalThis.location != null) {
        return stringToDartString(globalThis.location.href);
      }
      return null;
    },
_12998: () => {
        return typeof process != undefined &&
               Object.prototype.toString.call(process) == "[object process]" &&
               process.platform == "win32"
      },
_13002: s => stringToDartString(JSON.stringify(stringFromDartString(s))),
_13003: s => printToConsole(stringFromDartString(s)),
_13016: o => Object.keys(o),
_13017: (ms, c) =>
              setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
_13018: (handle) => clearTimeout(handle),
_13019: (ms, c) =>
          setInterval(() => dartInstance.exports.$invokeCallback(c), ms),
_13020: (handle) => clearInterval(handle),
_13021: (c) =>
              queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
_13022: () => Date.now(),
_13023: (a, i) => a.push(i),
_13026: (a, l) => a.length = l,
_13030: (a, s) => a.join(s),
_13033: (a, b) => a == b ? 0 : (a > b ? 1 : -1),
_13034: a => a.length,
_13036: (a, i) => a[i],
_13037: (a, i, v) => a[i] = v,
_13039: a => a.join(''),
_13040: (o, a, b) => o.replace(a, b),
_13042: (s, t) => s.split(t),
_13043: s => s.toLowerCase(),
_13044: s => s.toUpperCase(),
_13045: s => s.trim(),
_13047: s => s.trimRight(),
_13049: (s, p, i) => s.indexOf(p, i),
_13050: (s, p, i) => s.lastIndexOf(p, i),
_13052: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
_13053: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
_13054: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
_13055: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
_13056: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
_13057: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
_13058: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
_13061: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
_13062: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
_13063: Object.is,
_13066: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
_13068: o => o.buffer,
_13069: o => o.byteOffset,
_13070: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
_13071: (b, o) => new DataView(b, o),
_13073: Function.prototype.call.bind(DataView.prototype.getUint8),
_13074: Function.prototype.call.bind(DataView.prototype.setUint8),
_13075: Function.prototype.call.bind(DataView.prototype.getInt8),
_13076: Function.prototype.call.bind(DataView.prototype.setInt8),
_13077: Function.prototype.call.bind(DataView.prototype.getUint16),
_13078: Function.prototype.call.bind(DataView.prototype.setUint16),
_13079: Function.prototype.call.bind(DataView.prototype.getInt16),
_13080: Function.prototype.call.bind(DataView.prototype.setInt16),
_13081: Function.prototype.call.bind(DataView.prototype.getUint32),
_13082: Function.prototype.call.bind(DataView.prototype.setUint32),
_13083: Function.prototype.call.bind(DataView.prototype.getInt32),
_13084: Function.prototype.call.bind(DataView.prototype.setInt32),
_13089: Function.prototype.call.bind(DataView.prototype.getFloat32),
_13090: Function.prototype.call.bind(DataView.prototype.setFloat32),
_13091: Function.prototype.call.bind(DataView.prototype.getFloat64),
_13092: Function.prototype.call.bind(DataView.prototype.setFloat64),
_13098: s => stringToDartString(stringFromDartString(s).toUpperCase()),
_13099: s => stringToDartString(stringFromDartString(s).toLowerCase()),
_13101: (s, m) => {
          try {
            return new RegExp(s, m);
          } catch (e) {
            return String(e);
          }
        },
_13102: (x0,x1) => x0.exec(x1),
_13103: (x0,x1) => x0.test(x1),
_13104: (x0,x1) => x0.exec(x1),
_13105: (x0,x1) => x0.exec(x1),
_13106: x0 => x0.pop(),
_13110: (x0,x1,x2) => x0[x1] = x2,
_13112: o => o === undefined,
_13113: o => typeof o === 'boolean',
_13114: o => typeof o === 'number',
_13116: o => typeof o === 'string',
_13119: o => o instanceof Int8Array,
_13120: o => o instanceof Uint8Array,
_13121: o => o instanceof Uint8ClampedArray,
_13122: o => o instanceof Int16Array,
_13123: o => o instanceof Uint16Array,
_13124: o => o instanceof Int32Array,
_13125: o => o instanceof Uint32Array,
_13126: o => o instanceof Float32Array,
_13127: o => o instanceof Float64Array,
_13128: o => o instanceof ArrayBuffer,
_13129: o => o instanceof DataView,
_13130: o => o instanceof Array,
_13131: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
_13133: o => {
            const proto = Object.getPrototypeOf(o);
            return proto === Object.prototype || proto === null;
          },
_13134: o => o instanceof RegExp,
_13135: (l, r) => l === r,
_13136: o => o,
_13137: o => o,
_13138: o => o,
_13139: b => !!b,
_13140: o => o.length,
_13143: (o, i) => o[i],
_13144: f => f.dartFunction,
_13145: l => arrayFromDartList(Int8Array, l),
_13146: l => arrayFromDartList(Uint8Array, l),
_13147: l => arrayFromDartList(Uint8ClampedArray, l),
_13148: l => arrayFromDartList(Int16Array, l),
_13149: l => arrayFromDartList(Uint16Array, l),
_13150: l => arrayFromDartList(Int32Array, l),
_13151: l => arrayFromDartList(Uint32Array, l),
_13152: l => arrayFromDartList(Float32Array, l),
_13153: l => arrayFromDartList(Float64Array, l),
_13154: (data, length) => {
          const view = new DataView(new ArrayBuffer(length));
          for (let i = 0; i < length; i++) {
              view.setUint8(i, dartInstance.exports.$byteDataGetUint8(data, i));
          }
          return view;
        },
_13155: l => arrayFromDartList(Array, l),
_13156: stringFromDartString,
_13157: stringToDartString,
_13158: () => ({}),
_13159: () => [],
_13160: l => new Array(l),
_13161: () => globalThis,
_13164: (o, p) => o[p],
_13165: (o, p, v) => o[p] = v,
_13166: (o, m, a) => o[m].apply(o, a),
_13168: o => String(o),
_13170: s => {
      let jsString = stringFromDartString(s);
      if (/[[\]{}()*+?.\\^$|]/.test(jsString)) {
          jsString = jsString.replace(/[[\]{}()*+?.\\^$|]/g, '\\$&');
      }
      return stringToDartString(jsString);
    },
_13173: x0 => x0.index,
_13175: x0 => x0.length,
_13177: (x0,x1) => x0[x1],
_13179: (x0,x1) => x0.exec(x1),
_13181: x0 => x0.flags,
_13182: x0 => x0.multiline,
_13183: x0 => x0.ignoreCase,
_13184: x0 => x0.unicode,
_13185: x0 => x0.dotAll,
_13186: (x0,x1) => x0.lastIndex = x1,
_13187: (o, p) => p in o,
_13188: (o, p) => o[p],
_13189: (o, p, v) => o[p] = v
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

