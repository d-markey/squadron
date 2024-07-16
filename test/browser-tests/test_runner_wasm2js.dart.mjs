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
_51: (x0,x1) => x0.postMessage(x1),
_52: (x0,x1,x2) => x0.postMessage(x1,x2),
_53: () => new MessageChannel(),
_54: () => new MessageChannel(),
_55: f => finalizeWrapper(f,x0 => dartInstance.exports._55(f,x0)),
_56: f => finalizeWrapper(f,x0 => dartInstance.exports._56(f,x0)),
_57: x0 => x0.close(),
_58: x0 => x0.close(),
_59: () => new MessageChannel(),
_60: f => finalizeWrapper(f,x0 => dartInstance.exports._60(f,x0)),
_61: x0 => x0.close(),
_62: f => finalizeWrapper(f,x0 => dartInstance.exports._62(f,x0)),
_63: x0 => x0.close(),
_64: () => new MessageChannel(),
_65: x0 => new Worker(x0),
_66: f => finalizeWrapper(f,x0 => dartInstance.exports._66(f,x0)),
_67: f => finalizeWrapper(f,x0 => dartInstance.exports._67(f,x0)),
_68: f => finalizeWrapper(f,x0 => dartInstance.exports._68(f,x0)),
_69: (x0,x1) => x0.postMessage(x1),
_70: (x0,x1,x2) => x0.postMessage(x1,x2),
_71: x0 => x0.close(),
_72: x0 => x0.close(),
_73: x0 => x0.terminate(),
_74: x0 => globalThis.URL.revokeObjectURL(x0),
_75: x0 => ({type: x0}),
_76: (x0,x1) => new Blob(x0,x1),
_77: x0 => globalThis.URL.createObjectURL(x0),
_78: f => finalizeWrapper(f,x0 => dartInstance.exports._78(f,x0)),
_79: x0 => x0.close(),
_80: x0 => x0.close(),
_81: () => new MessageChannel(),
_82: (x0,x1,x2) => x0.postMessage(x1,x2),
_84: x0 => globalThis.dartPrint = x0,
_85: (x0,x1) => x0.querySelector(x1),
_86: f => finalizeWrapper(f,x0 => dartInstance.exports._86(f,x0)),
_87: f => finalizeWrapper(f,x0 => dartInstance.exports._87(f,x0)),
_88: f => finalizeWrapper(f,x0 => dartInstance.exports._88(f,x0)),
_89: x0 => globalThis.URL.revokeObjectURL(x0),
_90: x0 => x0.terminate(),
_91: f => finalizeWrapper(f,x0 => dartInstance.exports._91(f,x0)),
_92: f => finalizeWrapper(f,x0 => dartInstance.exports._92(f,x0)),
_93: f => finalizeWrapper(f,x0 => dartInstance.exports._93(f,x0)),
_94: x0 => globalThis.URL.revokeObjectURL(x0),
_95: x0 => x0.terminate(),
_96: f => finalizeWrapper(f,x0 => dartInstance.exports._96(f,x0)),
_97: f => finalizeWrapper(f,x0 => dartInstance.exports._97(f,x0)),
_98: x0 => x0.terminate(),
_99: f => finalizeWrapper(f,x0 => dartInstance.exports._99(f,x0)),
_100: f => finalizeWrapper(f,x0 => dartInstance.exports._100(f,x0)),
_101: x0 => globalThis.URL.revokeObjectURL(x0),
_102: x0 => x0.terminate(),
_103: f => finalizeWrapper(f,x0 => dartInstance.exports._103(f,x0)),
_104: f => finalizeWrapper(f,x0 => dartInstance.exports._104(f,x0)),
_105: x0 => globalThis.URL.revokeObjectURL(x0),
_106: x0 => x0.terminate(),
_107: (x0,x1) => x0.error(x1),
_108: (x0,x1) => x0.querySelectorAll(x1),
_109: (x0,x1) => x0.item(x1),
_110: (x0,x1) => x0.getNamedItem(x1),
_123: (x0,x1) => x0.createElement(x1),
_126: f => finalizeWrapper(f,x0 => dartInstance.exports._126(f,x0)),
_127: f => finalizeWrapper(f,x0 => dartInstance.exports._127(f,x0)),
_128: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
_129: (x0,x1,x2,x3) => x0.removeEventListener(x1,x2,x3),
_147: f => finalizeWrapper(f,x0 => dartInstance.exports._147(f,x0)),
_148: (x0,x1) => x0.log(x1),
_151: (x0,x1) => x0.appendChild(x1),
_152: (x0,x1,x2) => x0.scrollTo(x1,x2),
_186: (x0,x1) => x0.withCredentials = x1,
_189: x0 => x0.responseURL,
_190: x0 => x0.status,
_191: x0 => x0.statusText,
_192: (x0,x1) => x0.responseType = x1,
_194: x0 => x0.response,
_401: (x0,x1) => x0.onscroll = x1,
_1951: () => globalThis.window,
_2012: x0 => x0.location,
_2030: x0 => x0.parent,
_2032: x0 => x0.navigator,
_2299: x0 => x0.href,
_2300: x0 => x0.origin,
_2463: x0 => x0.filename,
_2464: x0 => x0.lineno,
_2466: x0 => x0.error,
_2513: x0 => x0.userAgent,
_2562: x0 => x0.data,
_2597: x0 => x0.port1,
_2598: x0 => x0.port2,
_2601: (x0,x1) => x0.onmessage = x1,
_2603: (x0,x1) => x0.onmessageerror = x1,
_2674: (x0,x1) => x0.onmessage = x1,
_2676: (x0,x1) => x0.onmessageerror = x1,
_2678: (x0,x1) => x0.onerror = x1,
_2679: x0 => x0.onerror,
_6838: x0 => x0.length,
_6925: () => globalThis.document,
_7365: x0 => x0.outerHTML,
_7367: x0 => x0.scrollTop,
_7371: x0 => x0.scrollHeight,
_7375: x0 => x0.clientHeight,
_7387: x0 => x0.attributes,
_7389: (x0,x1) => x0.innerHTML = x1,
_7423: x0 => x0.value,
_12768: () => globalThis.console,
_12792: v => stringToDartString(v.toString()),
_12803: Date.now,
_12805: s => new Date(s * 1000).getTimezoneOffset() * 60 ,
_12807: () => {
          let stackString = new Error().stack.toString();
          let frames = stackString.split('\n');
          let drop = 2;
          if (frames[0] === 'Error') {
              drop += 1;
          }
          return frames.slice(drop).join('\n');
        },
_12808: () => typeof dartUseDateNowForTicks !== "undefined",
_12809: () => 1000 * performance.now(),
_12810: () => Date.now(),
_12811: () => {
      // On browsers return `globalThis.location.href`
      if (globalThis.location != null) {
        return stringToDartString(globalThis.location.href);
      }
      return null;
    },
_12812: () => {
        return typeof process != undefined &&
               Object.prototype.toString.call(process) == "[object process]" &&
               process.platform == "win32"
      },
_12816: s => stringToDartString(JSON.stringify(stringFromDartString(s))),
_12817: s => printToConsole(stringFromDartString(s)),
_12830: o => Object.keys(o),
_12831: (ms, c) =>
              setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
_12832: (handle) => clearTimeout(handle),
_12833: (ms, c) =>
          setInterval(() => dartInstance.exports.$invokeCallback(c), ms),
_12834: (handle) => clearInterval(handle),
_12835: (c) =>
              queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
_12836: () => Date.now(),
_12837: (a, i) => a.push(i),
_12840: (a, l) => a.length = l,
_12844: (a, s) => a.join(s),
_12847: (a, b) => a == b ? 0 : (a > b ? 1 : -1),
_12848: a => a.length,
_12850: (a, i) => a[i],
_12851: (a, i, v) => a[i] = v,
_12853: a => a.join(''),
_12854: (o, a, b) => o.replace(a, b),
_12856: (s, t) => s.split(t),
_12857: s => s.toLowerCase(),
_12858: s => s.toUpperCase(),
_12859: s => s.trim(),
_12863: (s, p, i) => s.indexOf(p, i),
_12864: (s, p, i) => s.lastIndexOf(p, i),
_12866: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
_12867: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
_12868: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
_12869: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
_12870: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
_12871: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
_12872: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
_12875: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
_12876: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
_12877: Object.is,
_12880: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
_12882: o => o.buffer,
_12883: o => o.byteOffset,
_12884: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
_12885: (b, o) => new DataView(b, o),
_12887: Function.prototype.call.bind(DataView.prototype.getUint8),
_12888: Function.prototype.call.bind(DataView.prototype.setUint8),
_12889: Function.prototype.call.bind(DataView.prototype.getInt8),
_12890: Function.prototype.call.bind(DataView.prototype.setInt8),
_12891: Function.prototype.call.bind(DataView.prototype.getUint16),
_12892: Function.prototype.call.bind(DataView.prototype.setUint16),
_12893: Function.prototype.call.bind(DataView.prototype.getInt16),
_12894: Function.prototype.call.bind(DataView.prototype.setInt16),
_12895: Function.prototype.call.bind(DataView.prototype.getUint32),
_12896: Function.prototype.call.bind(DataView.prototype.setUint32),
_12897: Function.prototype.call.bind(DataView.prototype.getInt32),
_12898: Function.prototype.call.bind(DataView.prototype.setInt32),
_12903: Function.prototype.call.bind(DataView.prototype.getFloat32),
_12904: Function.prototype.call.bind(DataView.prototype.setFloat32),
_12905: Function.prototype.call.bind(DataView.prototype.getFloat64),
_12906: Function.prototype.call.bind(DataView.prototype.setFloat64),
_12912: s => stringToDartString(stringFromDartString(s).toUpperCase()),
_12913: s => stringToDartString(stringFromDartString(s).toLowerCase()),
_12915: (s, m) => {
          try {
            return new RegExp(s, m);
          } catch (e) {
            return String(e);
          }
        },
_12916: (x0,x1) => x0.exec(x1),
_12917: (x0,x1) => x0.test(x1),
_12918: (x0,x1) => x0.exec(x1),
_12919: (x0,x1) => x0.exec(x1),
_12920: x0 => x0.pop(),
_12924: (x0,x1,x2) => x0[x1] = x2,
_12926: o => o === undefined,
_12927: o => typeof o === 'boolean',
_12928: o => typeof o === 'number',
_12930: o => typeof o === 'string',
_12933: o => o instanceof Int8Array,
_12934: o => o instanceof Uint8Array,
_12935: o => o instanceof Uint8ClampedArray,
_12936: o => o instanceof Int16Array,
_12937: o => o instanceof Uint16Array,
_12938: o => o instanceof Int32Array,
_12939: o => o instanceof Uint32Array,
_12940: o => o instanceof Float32Array,
_12941: o => o instanceof Float64Array,
_12942: o => o instanceof ArrayBuffer,
_12943: o => o instanceof DataView,
_12944: o => o instanceof Array,
_12945: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
_12947: o => {
            const proto = Object.getPrototypeOf(o);
            return proto === Object.prototype || proto === null;
          },
_12948: o => o instanceof RegExp,
_12949: (l, r) => l === r,
_12950: o => o,
_12951: o => o,
_12952: o => o,
_12953: b => !!b,
_12954: o => o.length,
_12957: (o, i) => o[i],
_12958: f => f.dartFunction,
_12959: l => arrayFromDartList(Int8Array, l),
_12960: l => arrayFromDartList(Uint8Array, l),
_12961: l => arrayFromDartList(Uint8ClampedArray, l),
_12962: l => arrayFromDartList(Int16Array, l),
_12963: l => arrayFromDartList(Uint16Array, l),
_12964: l => arrayFromDartList(Int32Array, l),
_12965: l => arrayFromDartList(Uint32Array, l),
_12966: l => arrayFromDartList(Float32Array, l),
_12967: l => arrayFromDartList(Float64Array, l),
_12968: (data, length) => {
          const view = new DataView(new ArrayBuffer(length));
          for (let i = 0; i < length; i++) {
              view.setUint8(i, dartInstance.exports.$byteDataGetUint8(data, i));
          }
          return view;
        },
_12969: l => arrayFromDartList(Array, l),
_12970: stringFromDartString,
_12971: stringToDartString,
_12972: () => ({}),
_12973: () => [],
_12974: l => new Array(l),
_12975: () => globalThis,
_12978: (o, p) => o[p],
_12979: (o, p, v) => o[p] = v,
_12980: (o, m, a) => o[m].apply(o, a),
_12982: o => String(o),
_12984: s => {
      let jsString = stringFromDartString(s);
      if (/[[\]{}()*+?.\\^$|]/.test(jsString)) {
          jsString = jsString.replace(/[[\]{}()*+?.\\^$|]/g, '\\$&');
      }
      return stringToDartString(jsString);
    },
_12987: x0 => x0.index,
_12989: x0 => x0.length,
_12991: (x0,x1) => x0[x1],
_12993: (x0,x1) => x0.exec(x1),
_12995: x0 => x0.flags,
_12996: x0 => x0.multiline,
_12997: x0 => x0.ignoreCase,
_12998: x0 => x0.unicode,
_12999: x0 => x0.dotAll,
_13000: (x0,x1) => x0.lastIndex = x1,
_13001: (o, p) => p in o,
_13002: (o, p) => o[p],
_13003: (o, p, v) => o[p] = v
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

