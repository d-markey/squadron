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
_61: f => finalizeWrapper(f,x0 => dartInstance.exports._61(f,x0)),
_62: x0 => x0.close(),
_63: f => finalizeWrapper(f,x0 => dartInstance.exports._63(f,x0)),
_64: f => finalizeWrapper(f,x0 => dartInstance.exports._64(f,x0)),
_65: x0 => x0.close(),
_66: () => new MessageChannel(),
_67: x0 => new Worker(x0),
_68: f => finalizeWrapper(f,x0 => dartInstance.exports._68(f,x0)),
_69: f => finalizeWrapper(f,x0 => dartInstance.exports._69(f,x0)),
_70: f => finalizeWrapper(f,x0 => dartInstance.exports._70(f,x0)),
_71: f => finalizeWrapper(f,x0 => dartInstance.exports._71(f,x0)),
_72: (x0,x1) => x0.postMessage(x1),
_73: (x0,x1,x2) => x0.postMessage(x1,x2),
_74: x0 => x0.close(),
_75: x0 => x0.close(),
_76: x0 => x0.terminate(),
_77: x0 => globalThis.URL.revokeObjectURL(x0),
_78: x0 => ({type: x0}),
_79: (x0,x1) => new Blob(x0,x1),
_80: x0 => globalThis.URL.createObjectURL(x0),
_81: f => finalizeWrapper(f,x0 => dartInstance.exports._81(f,x0)),
_82: f => finalizeWrapper(f,x0 => dartInstance.exports._82(f,x0)),
_83: x0 => x0.close(),
_84: x0 => x0.close(),
_85: () => new MessageChannel(),
_86: (x0,x1,x2) => x0.postMessage(x1,x2),
_88: x0 => globalThis.dartPrint = x0,
_89: (x0,x1) => x0.querySelector(x1),
_90: f => finalizeWrapper(f,x0 => dartInstance.exports._90(f,x0)),
_91: f => finalizeWrapper(f,x0 => dartInstance.exports._91(f,x0)),
_92: f => finalizeWrapper(f,x0 => dartInstance.exports._92(f,x0)),
_93: x0 => globalThis.URL.revokeObjectURL(x0),
_94: x0 => x0.terminate(),
_95: f => finalizeWrapper(f,x0 => dartInstance.exports._95(f,x0)),
_96: f => finalizeWrapper(f,x0 => dartInstance.exports._96(f,x0)),
_97: f => finalizeWrapper(f,x0 => dartInstance.exports._97(f,x0)),
_98: x0 => globalThis.URL.revokeObjectURL(x0),
_99: x0 => x0.terminate(),
_100: f => finalizeWrapper(f,x0 => dartInstance.exports._100(f,x0)),
_101: f => finalizeWrapper(f,x0 => dartInstance.exports._101(f,x0)),
_102: x0 => x0.terminate(),
_103: f => finalizeWrapper(f,x0 => dartInstance.exports._103(f,x0)),
_104: f => finalizeWrapper(f,x0 => dartInstance.exports._104(f,x0)),
_105: x0 => globalThis.URL.revokeObjectURL(x0),
_106: x0 => x0.terminate(),
_107: f => finalizeWrapper(f,x0 => dartInstance.exports._107(f,x0)),
_108: f => finalizeWrapper(f,x0 => dartInstance.exports._108(f,x0)),
_109: x0 => globalThis.URL.revokeObjectURL(x0),
_110: x0 => x0.terminate(),
_111: (x0,x1) => x0.error(x1),
_112: (x0,x1) => x0.querySelectorAll(x1),
_113: (x0,x1) => x0.item(x1),
_114: (x0,x1) => x0.getNamedItem(x1),
_128: (x0,x1) => x0.createElement(x1),
_131: f => finalizeWrapper(f,x0 => dartInstance.exports._131(f,x0)),
_132: f => finalizeWrapper(f,x0 => dartInstance.exports._132(f,x0)),
_133: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
_134: (x0,x1,x2,x3) => x0.removeEventListener(x1,x2,x3),
_152: f => finalizeWrapper(f,x0 => dartInstance.exports._152(f,x0)),
_153: (x0,x1) => x0.log(x1),
_156: (x0,x1) => x0.appendChild(x1),
_157: (x0,x1,x2) => x0.scrollTo(x1,x2),
_191: (x0,x1) => x0.withCredentials = x1,
_194: x0 => x0.responseURL,
_195: x0 => x0.status,
_196: x0 => x0.statusText,
_197: (x0,x1) => x0.responseType = x1,
_199: x0 => x0.response,
_406: (x0,x1) => x0.onscroll = x1,
_1956: () => globalThis.window,
_2017: x0 => x0.location,
_2035: x0 => x0.parent,
_2037: x0 => x0.navigator,
_2304: x0 => x0.href,
_2305: x0 => x0.origin,
_2468: x0 => x0.filename,
_2469: x0 => x0.lineno,
_2471: x0 => x0.error,
_2518: x0 => x0.userAgent,
_2567: x0 => x0.data,
_2602: x0 => x0.port1,
_2603: x0 => x0.port2,
_2606: (x0,x1) => x0.onmessage = x1,
_2608: (x0,x1) => x0.onmessageerror = x1,
_2679: (x0,x1) => x0.onmessage = x1,
_2681: (x0,x1) => x0.onmessageerror = x1,
_2683: (x0,x1) => x0.onerror = x1,
_2684: x0 => x0.onerror,
_6843: x0 => x0.length,
_6930: () => globalThis.document,
_7370: x0 => x0.outerHTML,
_7372: x0 => x0.scrollTop,
_7376: x0 => x0.scrollHeight,
_7380: x0 => x0.clientHeight,
_7392: x0 => x0.attributes,
_7394: (x0,x1) => x0.innerHTML = x1,
_7428: x0 => x0.value,
_12773: () => globalThis.console,
_12797: v => stringToDartString(v.toString()),
_12808: Date.now,
_12810: s => new Date(s * 1000).getTimezoneOffset() * 60 ,
_12812: () => {
          let stackString = new Error().stack.toString();
          let frames = stackString.split('\n');
          let drop = 2;
          if (frames[0] === 'Error') {
              drop += 1;
          }
          return frames.slice(drop).join('\n');
        },
_12813: () => typeof dartUseDateNowForTicks !== "undefined",
_12814: () => 1000 * performance.now(),
_12815: () => Date.now(),
_12816: () => {
      // On browsers return `globalThis.location.href`
      if (globalThis.location != null) {
        return stringToDartString(globalThis.location.href);
      }
      return null;
    },
_12817: () => {
        return typeof process != undefined &&
               Object.prototype.toString.call(process) == "[object process]" &&
               process.platform == "win32"
      },
_12821: s => stringToDartString(JSON.stringify(stringFromDartString(s))),
_12822: s => printToConsole(stringFromDartString(s)),
_12835: o => Object.keys(o),
_12836: (ms, c) =>
              setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
_12837: (handle) => clearTimeout(handle),
_12838: (ms, c) =>
          setInterval(() => dartInstance.exports.$invokeCallback(c), ms),
_12839: (handle) => clearInterval(handle),
_12840: (c) =>
              queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
_12841: () => Date.now(),
_12842: (a, i) => a.push(i),
_12845: (a, l) => a.length = l,
_12849: (a, s) => a.join(s),
_12852: (a, b) => a == b ? 0 : (a > b ? 1 : -1),
_12853: a => a.length,
_12855: (a, i) => a[i],
_12856: (a, i, v) => a[i] = v,
_12858: a => a.join(''),
_12859: (o, a, b) => o.replace(a, b),
_12861: (s, t) => s.split(t),
_12862: s => s.toLowerCase(),
_12863: s => s.toUpperCase(),
_12864: s => s.trim(),
_12868: (s, p, i) => s.indexOf(p, i),
_12869: (s, p, i) => s.lastIndexOf(p, i),
_12871: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
_12872: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
_12873: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
_12874: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
_12875: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
_12876: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
_12877: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
_12880: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
_12881: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
_12882: Object.is,
_12885: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
_12887: o => o.buffer,
_12888: o => o.byteOffset,
_12889: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
_12890: (b, o) => new DataView(b, o),
_12892: Function.prototype.call.bind(DataView.prototype.getUint8),
_12893: Function.prototype.call.bind(DataView.prototype.setUint8),
_12894: Function.prototype.call.bind(DataView.prototype.getInt8),
_12895: Function.prototype.call.bind(DataView.prototype.setInt8),
_12896: Function.prototype.call.bind(DataView.prototype.getUint16),
_12897: Function.prototype.call.bind(DataView.prototype.setUint16),
_12898: Function.prototype.call.bind(DataView.prototype.getInt16),
_12899: Function.prototype.call.bind(DataView.prototype.setInt16),
_12900: Function.prototype.call.bind(DataView.prototype.getUint32),
_12901: Function.prototype.call.bind(DataView.prototype.setUint32),
_12902: Function.prototype.call.bind(DataView.prototype.getInt32),
_12903: Function.prototype.call.bind(DataView.prototype.setInt32),
_12908: Function.prototype.call.bind(DataView.prototype.getFloat32),
_12909: Function.prototype.call.bind(DataView.prototype.setFloat32),
_12910: Function.prototype.call.bind(DataView.prototype.getFloat64),
_12911: Function.prototype.call.bind(DataView.prototype.setFloat64),
_12917: s => stringToDartString(stringFromDartString(s).toUpperCase()),
_12918: s => stringToDartString(stringFromDartString(s).toLowerCase()),
_12920: (s, m) => {
          try {
            return new RegExp(s, m);
          } catch (e) {
            return String(e);
          }
        },
_12921: (x0,x1) => x0.exec(x1),
_12922: (x0,x1) => x0.test(x1),
_12923: (x0,x1) => x0.exec(x1),
_12924: (x0,x1) => x0.exec(x1),
_12925: x0 => x0.pop(),
_12929: (x0,x1,x2) => x0[x1] = x2,
_12931: o => o === undefined,
_12932: o => typeof o === 'boolean',
_12933: o => typeof o === 'number',
_12935: o => typeof o === 'string',
_12938: o => o instanceof Int8Array,
_12939: o => o instanceof Uint8Array,
_12940: o => o instanceof Uint8ClampedArray,
_12941: o => o instanceof Int16Array,
_12942: o => o instanceof Uint16Array,
_12943: o => o instanceof Int32Array,
_12944: o => o instanceof Uint32Array,
_12945: o => o instanceof Float32Array,
_12946: o => o instanceof Float64Array,
_12947: o => o instanceof ArrayBuffer,
_12948: o => o instanceof DataView,
_12949: o => o instanceof Array,
_12950: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
_12952: o => {
            const proto = Object.getPrototypeOf(o);
            return proto === Object.prototype || proto === null;
          },
_12953: o => o instanceof RegExp,
_12954: (l, r) => l === r,
_12955: o => o,
_12956: o => o,
_12957: o => o,
_12958: b => !!b,
_12959: o => o.length,
_12962: (o, i) => o[i],
_12963: f => f.dartFunction,
_12964: l => arrayFromDartList(Int8Array, l),
_12965: l => arrayFromDartList(Uint8Array, l),
_12966: l => arrayFromDartList(Uint8ClampedArray, l),
_12967: l => arrayFromDartList(Int16Array, l),
_12968: l => arrayFromDartList(Uint16Array, l),
_12969: l => arrayFromDartList(Int32Array, l),
_12970: l => arrayFromDartList(Uint32Array, l),
_12971: l => arrayFromDartList(Float32Array, l),
_12972: l => arrayFromDartList(Float64Array, l),
_12973: (data, length) => {
          const view = new DataView(new ArrayBuffer(length));
          for (let i = 0; i < length; i++) {
              view.setUint8(i, dartInstance.exports.$byteDataGetUint8(data, i));
          }
          return view;
        },
_12974: l => arrayFromDartList(Array, l),
_12975: stringFromDartString,
_12976: stringToDartString,
_12977: () => ({}),
_12978: () => [],
_12979: l => new Array(l),
_12980: () => globalThis,
_12983: (o, p) => o[p],
_12984: (o, p, v) => o[p] = v,
_12985: (o, m, a) => o[m].apply(o, a),
_12987: o => String(o),
_12989: s => {
      let jsString = stringFromDartString(s);
      if (/[[\]{}()*+?.\\^$|]/.test(jsString)) {
          jsString = jsString.replace(/[[\]{}()*+?.\\^$|]/g, '\\$&');
      }
      return stringToDartString(jsString);
    },
_12992: x0 => x0.index,
_12994: x0 => x0.length,
_12996: (x0,x1) => x0[x1],
_12998: (x0,x1) => x0.exec(x1),
_13000: x0 => x0.flags,
_13001: x0 => x0.multiline,
_13002: x0 => x0.ignoreCase,
_13003: x0 => x0.unicode,
_13004: x0 => x0.dotAll,
_13005: (x0,x1) => x0.lastIndex = x1,
_13006: (o, p) => p in o,
_13007: (o, p) => o[p],
_13008: (o, p, v) => o[p] = v
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

