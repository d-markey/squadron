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
_69: (x0,x1,x2) => x0.postMessage(x1,x2),
_70: x0 => x0.close(),
_71: x0 => x0.close(),
_72: x0 => x0.terminate(),
_73: f => finalizeWrapper(f,x0 => dartInstance.exports._73(f,x0)),
_74: x0 => x0.close(),
_75: x0 => x0.close(),
_76: () => new MessageChannel(),
_78: x0 => globalThis.dartPrint = x0,
_79: (x0,x1) => x0.querySelector(x1),
_80: f => finalizeWrapper(f,x0 => dartInstance.exports._80(f,x0)),
_81: () => globalThis.self,
_83: (x0,x1) => x0.querySelectorAll(x1),
_84: (x0,x1) => x0.item(x1),
_85: (x0,x1) => x0.getNamedItem(x1),
_86: (x0,x1) => x0.log(x1),
_87: f => finalizeWrapper(f,x0 => dartInstance.exports._87(f,x0)),
_88: (x0,x1) => x0.log(x1),
_89: f => finalizeWrapper(f,x0 => dartInstance.exports._89(f,x0)),
_90: (x0,x1) => x0.log(x1),
_91: f => finalizeWrapper(f,x0 => dartInstance.exports._91(f,x0)),
_92: (x0,x1) => x0.postMessage(x1),
_93: x0 => x0.terminate(),
_94: f => finalizeWrapper(f,x0 => dartInstance.exports._94(f,x0)),
_95: f => finalizeWrapper(f,x0 => dartInstance.exports._95(f,x0)),
_96: x0 => x0.terminate(),
_97: f => finalizeWrapper(f,x0 => dartInstance.exports._97(f,x0)),
_98: f => finalizeWrapper(f,x0 => dartInstance.exports._98(f,x0)),
_99: x0 => x0.terminate(),
_100: f => finalizeWrapper(f,x0 => dartInstance.exports._100(f,x0)),
_101: f => finalizeWrapper(f,x0 => dartInstance.exports._101(f,x0)),
_102: f => finalizeWrapper(f,x0 => dartInstance.exports._102(f,x0)),
_103: x0 => x0.terminate(),
_120: f => finalizeWrapper(f,x0 => dartInstance.exports._120(f,x0)),
_121: f => finalizeWrapper(f,x0 => dartInstance.exports._121(f,x0)),
_122: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
_123: (x0,x1,x2,x3) => x0.removeEventListener(x1,x2,x3),
_141: (x0,x1,x2) => x0.scrollTo(x1,x2),
_175: (x0,x1) => x0.withCredentials = x1,
_178: x0 => x0.responseURL,
_179: x0 => x0.status,
_180: x0 => x0.statusText,
_181: (x0,x1) => x0.responseType = x1,
_183: x0 => x0.response,
_1940: () => globalThis.window,
_2001: x0 => x0.location,
_2021: x0 => x0.navigator,
_2288: x0 => x0.href,
_2451: x0 => x0.message,
_2452: x0 => x0.filename,
_2453: x0 => x0.lineno,
_2502: x0 => x0.userAgent,
_2551: x0 => x0.data,
_2586: x0 => x0.port1,
_2587: x0 => x0.port2,
_2590: (x0,x1) => x0.onmessage = x1,
_2663: (x0,x1) => x0.onmessage = x1,
_2665: (x0,x1) => x0.onmessageerror = x1,
_2667: (x0,x1) => x0.onerror = x1,
_6827: x0 => x0.length,
_6901: x0 => x0.parentElement,
_6914: () => globalThis.document,
_7354: x0 => x0.outerHTML,
_7376: x0 => x0.attributes,
_7378: (x0,x1) => x0.innerHTML = x1,
_7379: x0 => x0.innerHTML,
_7412: x0 => x0.value,
_12758: () => globalThis.console,
_12782: v => stringToDartString(v.toString()),
_12793: Date.now,
_12795: s => new Date(s * 1000).getTimezoneOffset() * 60 ,
_12797: () => {
          let stackString = new Error().stack.toString();
          let frames = stackString.split('\n');
          let drop = 2;
          if (frames[0] === 'Error') {
              drop += 1;
          }
          return frames.slice(drop).join('\n');
        },
_12798: () => typeof dartUseDateNowForTicks !== "undefined",
_12799: () => 1000 * performance.now(),
_12800: () => Date.now(),
_12801: () => {
      // On browsers return `globalThis.location.href`
      if (globalThis.location != null) {
        return stringToDartString(globalThis.location.href);
      }
      return null;
    },
_12802: () => {
        return typeof process != undefined &&
               Object.prototype.toString.call(process) == "[object process]" &&
               process.platform == "win32"
      },
_12806: s => stringToDartString(JSON.stringify(stringFromDartString(s))),
_12807: s => printToConsole(stringFromDartString(s)),
_12820: o => Object.keys(o),
_12821: (ms, c) =>
              setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
_12822: (handle) => clearTimeout(handle),
_12823: (ms, c) =>
          setInterval(() => dartInstance.exports.$invokeCallback(c), ms),
_12824: (handle) => clearInterval(handle),
_12825: (c) =>
              queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
_12826: () => Date.now(),
_12827: (a, i) => a.push(i),
_12830: (a, l) => a.length = l,
_12834: (a, s) => a.join(s),
_12837: (a, b) => a == b ? 0 : (a > b ? 1 : -1),
_12838: a => a.length,
_12840: (a, i) => a[i],
_12841: (a, i, v) => a[i] = v,
_12843: a => a.join(''),
_12844: (o, a, b) => o.replace(a, b),
_12846: (s, t) => s.split(t),
_12847: s => s.toLowerCase(),
_12848: s => s.toUpperCase(),
_12849: s => s.trim(),
_12851: s => s.trimRight(),
_12853: (s, p, i) => s.indexOf(p, i),
_12854: (s, p, i) => s.lastIndexOf(p, i),
_12856: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
_12857: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
_12858: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
_12859: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
_12860: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
_12861: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
_12862: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
_12865: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
_12866: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
_12867: Object.is,
_12870: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
_12872: o => o.buffer,
_12873: o => o.byteOffset,
_12874: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
_12875: (b, o) => new DataView(b, o),
_12877: Function.prototype.call.bind(DataView.prototype.getUint8),
_12878: Function.prototype.call.bind(DataView.prototype.setUint8),
_12879: Function.prototype.call.bind(DataView.prototype.getInt8),
_12880: Function.prototype.call.bind(DataView.prototype.setInt8),
_12881: Function.prototype.call.bind(DataView.prototype.getUint16),
_12882: Function.prototype.call.bind(DataView.prototype.setUint16),
_12883: Function.prototype.call.bind(DataView.prototype.getInt16),
_12884: Function.prototype.call.bind(DataView.prototype.setInt16),
_12885: Function.prototype.call.bind(DataView.prototype.getUint32),
_12886: Function.prototype.call.bind(DataView.prototype.setUint32),
_12887: Function.prototype.call.bind(DataView.prototype.getInt32),
_12888: Function.prototype.call.bind(DataView.prototype.setInt32),
_12893: Function.prototype.call.bind(DataView.prototype.getFloat32),
_12894: Function.prototype.call.bind(DataView.prototype.setFloat32),
_12895: Function.prototype.call.bind(DataView.prototype.getFloat64),
_12896: Function.prototype.call.bind(DataView.prototype.setFloat64),
_12902: s => stringToDartString(stringFromDartString(s).toUpperCase()),
_12903: s => stringToDartString(stringFromDartString(s).toLowerCase()),
_12905: (s, m) => {
          try {
            return new RegExp(s, m);
          } catch (e) {
            return String(e);
          }
        },
_12906: (x0,x1) => x0.exec(x1),
_12907: (x0,x1) => x0.test(x1),
_12908: (x0,x1) => x0.exec(x1),
_12909: (x0,x1) => x0.exec(x1),
_12910: x0 => x0.pop(),
_12916: o => o === undefined,
_12917: o => typeof o === 'boolean',
_12918: o => typeof o === 'number',
_12920: o => typeof o === 'string',
_12923: o => o instanceof Int8Array,
_12924: o => o instanceof Uint8Array,
_12925: o => o instanceof Uint8ClampedArray,
_12926: o => o instanceof Int16Array,
_12927: o => o instanceof Uint16Array,
_12928: o => o instanceof Int32Array,
_12929: o => o instanceof Uint32Array,
_12930: o => o instanceof Float32Array,
_12931: o => o instanceof Float64Array,
_12932: o => o instanceof ArrayBuffer,
_12933: o => o instanceof DataView,
_12934: o => o instanceof Array,
_12935: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
_12937: o => {
            const proto = Object.getPrototypeOf(o);
            return proto === Object.prototype || proto === null;
          },
_12938: o => o instanceof RegExp,
_12939: (l, r) => l === r,
_12940: o => o,
_12941: o => o,
_12942: o => o,
_12943: b => !!b,
_12944: o => o.length,
_12947: (o, i) => o[i],
_12948: f => f.dartFunction,
_12949: l => arrayFromDartList(Int8Array, l),
_12950: l => arrayFromDartList(Uint8Array, l),
_12951: l => arrayFromDartList(Uint8ClampedArray, l),
_12952: l => arrayFromDartList(Int16Array, l),
_12953: l => arrayFromDartList(Uint16Array, l),
_12954: l => arrayFromDartList(Int32Array, l),
_12955: l => arrayFromDartList(Uint32Array, l),
_12956: l => arrayFromDartList(Float32Array, l),
_12957: l => arrayFromDartList(Float64Array, l),
_12958: (data, length) => {
          const view = new DataView(new ArrayBuffer(length));
          for (let i = 0; i < length; i++) {
              view.setUint8(i, dartInstance.exports.$byteDataGetUint8(data, i));
          }
          return view;
        },
_12959: l => arrayFromDartList(Array, l),
_12960: stringFromDartString,
_12961: stringToDartString,
_12962: () => ({}),
_12963: () => [],
_12964: l => new Array(l),
_12965: () => globalThis,
_12968: (o, p) => o[p],
_12969: (o, p, v) => o[p] = v,
_12970: (o, m, a) => o[m].apply(o, a),
_12972: o => String(o),
_12977: x0 => x0.index,
_12979: x0 => x0.length,
_12981: (x0,x1) => x0[x1],
_12983: (x0,x1) => x0.exec(x1),
_12985: x0 => x0.flags,
_12986: x0 => x0.multiline,
_12987: x0 => x0.ignoreCase,
_12988: x0 => x0.unicode,
_12989: x0 => x0.dotAll,
_12990: (x0,x1) => x0.lastIndex = x1,
_12992: (o, p) => o[p]
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

