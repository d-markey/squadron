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
_56: x0 => x0.close(),
_57: x0 => x0.close(),
_58: () => new MessageChannel(),
_59: f => finalizeWrapper(f,x0 => dartInstance.exports._59(f,x0)),
_60: x0 => x0.close(),
_61: f => finalizeWrapper(f,x0 => dartInstance.exports._61(f,x0)),
_62: x0 => x0.close(),
_63: () => new MessageChannel(),
_64: x0 => new Worker(x0),
_65: f => finalizeWrapper(f,x0 => dartInstance.exports._65(f,x0)),
_66: f => finalizeWrapper(f,x0 => dartInstance.exports._66(f,x0)),
_67: x0 => x0.terminate(),
_68: f => finalizeWrapper(f,x0 => dartInstance.exports._68(f,x0)),
_69: (x0,x1) => x0.postMessage(x1),
_70: (x0,x1,x2) => x0.postMessage(x1,x2),
_71: x0 => x0.close(),
_72: x0 => x0.close(),
_73: x0 => x0.terminate(),
_74: f => finalizeWrapper(f,x0 => dartInstance.exports._74(f,x0)),
_75: x0 => x0.close(),
_76: x0 => x0.close(),
_77: () => new MessageChannel(),
_79: x0 => globalThis.dartPrint = x0,
_80: (x0,x1) => x0.querySelector(x1),
_81: f => finalizeWrapper(f,x0 => dartInstance.exports._81(f,x0)),
_90: (x0,x1) => x0.error(x1),
_91: (x0,x1) => x0.querySelectorAll(x1),
_92: (x0,x1) => x0.item(x1),
_93: (x0,x1) => x0.getNamedItem(x1),
_94: f => finalizeWrapper(f,x0 => dartInstance.exports._94(f,x0)),
_95: f => finalizeWrapper(f,x0 => dartInstance.exports._95(f,x0)),
_96: f => finalizeWrapper(f,x0 => dartInstance.exports._96(f,x0)),
_97: x0 => x0.terminate(),
_98: f => finalizeWrapper(f,x0 => dartInstance.exports._98(f,x0)),
_99: f => finalizeWrapper(f,x0 => dartInstance.exports._99(f,x0)),
_100: x0 => x0.terminate(),
_101: f => finalizeWrapper(f,x0 => dartInstance.exports._101(f,x0)),
_102: f => finalizeWrapper(f,x0 => dartInstance.exports._102(f,x0)),
_103: x0 => x0.terminate(),
_104: f => finalizeWrapper(f,x0 => dartInstance.exports._104(f,x0)),
_105: f => finalizeWrapper(f,x0 => dartInstance.exports._105(f,x0)),
_106: x0 => x0.terminate(),
_111: (x0,x1) => x0.createElement(x1),
_114: f => finalizeWrapper(f,x0 => dartInstance.exports._114(f,x0)),
_115: f => finalizeWrapper(f,x0 => dartInstance.exports._115(f,x0)),
_116: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
_117: (x0,x1,x2,x3) => x0.removeEventListener(x1,x2,x3),
_135: f => finalizeWrapper(f,x0 => dartInstance.exports._135(f,x0)),
_136: (x0,x1) => x0.log(x1),
_139: (x0,x1) => x0.appendChild(x1),
_140: (x0,x1,x2) => x0.scrollTo(x1,x2),
_174: (x0,x1) => x0.withCredentials = x1,
_177: x0 => x0.responseURL,
_178: x0 => x0.status,
_179: x0 => x0.statusText,
_180: (x0,x1) => x0.responseType = x1,
_182: x0 => x0.response,
_389: (x0,x1) => x0.onscroll = x1,
_1939: () => globalThis.window,
_2000: x0 => x0.location,
_2020: x0 => x0.navigator,
_2287: x0 => x0.href,
_2450: x0 => x0.message,
_2451: x0 => x0.filename,
_2452: x0 => x0.lineno,
_2454: x0 => x0.error,
_2501: x0 => x0.userAgent,
_2550: x0 => x0.data,
_2585: x0 => x0.port1,
_2586: x0 => x0.port2,
_2589: (x0,x1) => x0.onmessage = x1,
_2662: (x0,x1) => x0.onmessage = x1,
_2664: (x0,x1) => x0.onmessageerror = x1,
_2666: (x0,x1) => x0.onerror = x1,
_6826: x0 => x0.length,
_6913: () => globalThis.document,
_7353: x0 => x0.outerHTML,
_7355: x0 => x0.scrollTop,
_7359: x0 => x0.scrollHeight,
_7363: x0 => x0.clientHeight,
_7375: x0 => x0.attributes,
_7377: (x0,x1) => x0.innerHTML = x1,
_7411: x0 => x0.value,
_12757: () => globalThis.console,
_12781: v => stringToDartString(v.toString()),
_12792: Date.now,
_12794: s => new Date(s * 1000).getTimezoneOffset() * 60 ,
_12796: () => {
          let stackString = new Error().stack.toString();
          let frames = stackString.split('\n');
          let drop = 2;
          if (frames[0] === 'Error') {
              drop += 1;
          }
          return frames.slice(drop).join('\n');
        },
_12797: () => typeof dartUseDateNowForTicks !== "undefined",
_12798: () => 1000 * performance.now(),
_12799: () => Date.now(),
_12800: () => {
      // On browsers return `globalThis.location.href`
      if (globalThis.location != null) {
        return stringToDartString(globalThis.location.href);
      }
      return null;
    },
_12801: () => {
        return typeof process != undefined &&
               Object.prototype.toString.call(process) == "[object process]" &&
               process.platform == "win32"
      },
_12805: s => stringToDartString(JSON.stringify(stringFromDartString(s))),
_12806: s => printToConsole(stringFromDartString(s)),
_12819: o => Object.keys(o),
_12820: (ms, c) =>
              setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
_12821: (handle) => clearTimeout(handle),
_12822: (ms, c) =>
          setInterval(() => dartInstance.exports.$invokeCallback(c), ms),
_12823: (handle) => clearInterval(handle),
_12824: (c) =>
              queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
_12825: () => Date.now(),
_12826: (a, i) => a.push(i),
_12829: (a, l) => a.length = l,
_12833: (a, s) => a.join(s),
_12836: (a, b) => a == b ? 0 : (a > b ? 1 : -1),
_12837: a => a.length,
_12839: (a, i) => a[i],
_12840: (a, i, v) => a[i] = v,
_12842: a => a.join(''),
_12843: (o, a, b) => o.replace(a, b),
_12845: (s, t) => s.split(t),
_12846: s => s.toLowerCase(),
_12847: s => s.toUpperCase(),
_12848: s => s.trim(),
_12852: (s, p, i) => s.indexOf(p, i),
_12853: (s, p, i) => s.lastIndexOf(p, i),
_12855: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
_12856: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
_12857: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
_12858: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
_12859: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
_12860: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
_12861: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
_12864: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
_12865: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
_12866: Object.is,
_12869: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
_12871: o => o.buffer,
_12872: o => o.byteOffset,
_12873: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
_12874: (b, o) => new DataView(b, o),
_12876: Function.prototype.call.bind(DataView.prototype.getUint8),
_12877: Function.prototype.call.bind(DataView.prototype.setUint8),
_12878: Function.prototype.call.bind(DataView.prototype.getInt8),
_12879: Function.prototype.call.bind(DataView.prototype.setInt8),
_12880: Function.prototype.call.bind(DataView.prototype.getUint16),
_12881: Function.prototype.call.bind(DataView.prototype.setUint16),
_12882: Function.prototype.call.bind(DataView.prototype.getInt16),
_12883: Function.prototype.call.bind(DataView.prototype.setInt16),
_12884: Function.prototype.call.bind(DataView.prototype.getUint32),
_12885: Function.prototype.call.bind(DataView.prototype.setUint32),
_12886: Function.prototype.call.bind(DataView.prototype.getInt32),
_12887: Function.prototype.call.bind(DataView.prototype.setInt32),
_12892: Function.prototype.call.bind(DataView.prototype.getFloat32),
_12893: Function.prototype.call.bind(DataView.prototype.setFloat32),
_12894: Function.prototype.call.bind(DataView.prototype.getFloat64),
_12895: Function.prototype.call.bind(DataView.prototype.setFloat64),
_12901: s => stringToDartString(stringFromDartString(s).toUpperCase()),
_12902: s => stringToDartString(stringFromDartString(s).toLowerCase()),
_12904: (s, m) => {
          try {
            return new RegExp(s, m);
          } catch (e) {
            return String(e);
          }
        },
_12905: (x0,x1) => x0.exec(x1),
_12906: (x0,x1) => x0.test(x1),
_12907: (x0,x1) => x0.exec(x1),
_12908: (x0,x1) => x0.exec(x1),
_12909: x0 => x0.pop(),
_12915: o => o === undefined,
_12916: o => typeof o === 'boolean',
_12917: o => typeof o === 'number',
_12919: o => typeof o === 'string',
_12922: o => o instanceof Int8Array,
_12923: o => o instanceof Uint8Array,
_12924: o => o instanceof Uint8ClampedArray,
_12925: o => o instanceof Int16Array,
_12926: o => o instanceof Uint16Array,
_12927: o => o instanceof Int32Array,
_12928: o => o instanceof Uint32Array,
_12929: o => o instanceof Float32Array,
_12930: o => o instanceof Float64Array,
_12931: o => o instanceof ArrayBuffer,
_12932: o => o instanceof DataView,
_12933: o => o instanceof Array,
_12934: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
_12936: o => {
            const proto = Object.getPrototypeOf(o);
            return proto === Object.prototype || proto === null;
          },
_12937: o => o instanceof RegExp,
_12938: (l, r) => l === r,
_12939: o => o,
_12940: o => o,
_12941: o => o,
_12942: b => !!b,
_12943: o => o.length,
_12946: (o, i) => o[i],
_12947: f => f.dartFunction,
_12948: l => arrayFromDartList(Int8Array, l),
_12949: l => arrayFromDartList(Uint8Array, l),
_12950: l => arrayFromDartList(Uint8ClampedArray, l),
_12951: l => arrayFromDartList(Int16Array, l),
_12952: l => arrayFromDartList(Uint16Array, l),
_12953: l => arrayFromDartList(Int32Array, l),
_12954: l => arrayFromDartList(Uint32Array, l),
_12955: l => arrayFromDartList(Float32Array, l),
_12956: l => arrayFromDartList(Float64Array, l),
_12957: (data, length) => {
          const view = new DataView(new ArrayBuffer(length));
          for (let i = 0; i < length; i++) {
              view.setUint8(i, dartInstance.exports.$byteDataGetUint8(data, i));
          }
          return view;
        },
_12958: l => arrayFromDartList(Array, l),
_12959: stringFromDartString,
_12960: stringToDartString,
_12961: () => ({}),
_12962: () => [],
_12963: l => new Array(l),
_12964: () => globalThis,
_12967: (o, p) => o[p],
_12968: (o, p, v) => o[p] = v,
_12969: (o, m, a) => o[m].apply(o, a),
_12971: o => String(o),
_12976: x0 => x0.index,
_12978: x0 => x0.length,
_12980: (x0,x1) => x0[x1],
_12982: (x0,x1) => x0.exec(x1),
_12984: x0 => x0.flags,
_12985: x0 => x0.multiline,
_12986: x0 => x0.ignoreCase,
_12987: x0 => x0.unicode,
_12988: x0 => x0.dotAll,
_12989: (x0,x1) => x0.lastIndex = x1,
_12991: (o, p) => o[p]
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

