// Compiles a dart2wasm-generated main module from `source` which can then
// instantiatable via the `instantiate` method.
//
// `source` needs to be a `Response` object (or promise thereof) e.g. created
// via the `fetch()` JS API.
export async function compileStreaming(source) {
  const builtins = {builtins: ['js-string']};
  return new CompiledApp(
      await WebAssembly.compileStreaming(source, builtins), builtins);
}

// Compiles a dart2wasm-generated wasm modules from `bytes` which is then
// instantiatable via the `instantiate` method.
export async function compile(bytes) {
  const builtins = {builtins: ['js-string']};
  return new CompiledApp(await WebAssembly.compile(bytes, builtins), builtins);
}

// DEPRECATED: Please use `compile` or `compileStreaming` to get a compiled app,
// use `instantiate` method to get an instantiated app and then call
// `invokeMain` to invoke the main function.
export async function instantiate(modulePromise, importObjectPromise) {
  var moduleOrCompiledApp = await modulePromise;
  if (!(moduleOrCompiledApp instanceof CompiledApp)) {
    moduleOrCompiledApp = new CompiledApp(moduleOrCompiledApp);
  }
  const instantiatedApp = await moduleOrCompiledApp.instantiate(await importObjectPromise);
  return instantiatedApp.instantiatedModule;
}

// DEPRECATED: Please use `compile` or `compileStreaming` to get a compiled app,
// use `instantiate` method to get an instantiated app and then call
// `invokeMain` to invoke the main function.
export const invoke = (moduleInstance, ...args) => {
  moduleInstance.exports.$invokeMain(args);
}

class CompiledApp {
  constructor(module, builtins) {
    this.module = module;
    this.builtins = builtins;
  }

  // The second argument is an options object containing:
  // `loadDeferredWasm` is a JS function that takes a module name matching a
  //   wasm file produced by the dart2wasm compiler and returns the bytes to
  //   load the module. These bytes can be in either a format supported by
  //   `WebAssembly.compile` or `WebAssembly.compileStreaming`.
  async instantiate(additionalImports, {loadDeferredWasm, loadDynamicModule} = {}) {
    let dartInstance;

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

    // A special symbol attached to functions that wrap Dart functions.
    const jsWrappedDartFunctionSymbol = Symbol("JSWrappedDartFunction");

    function finalizeWrapper(dartFunction, wrapped) {
      wrapped.dartFunction = dartFunction;
      wrapped[jsWrappedDartFunctionSymbol] = true;
      return wrapped;
    }

    // Imports
    const dart2wasm = {
            _3: (o, t) => typeof o === t,
      _4: (o, c) => o instanceof c,
      _27: (o) => !!o,
      _36: () => new Array(),
      _37: x0 => new Array(x0),
      _39: x0 => x0.length,
      _41: (x0,x1) => x0[x1],
      _42: (x0,x1,x2) => x0[x1] = x2,
      _45: (x0,x1,x2) => new DataView(x0,x1,x2),
      _47: x0 => new Int8Array(x0),
      _48: (x0,x1,x2) => new Uint8Array(x0,x1,x2),
      _49: x0 => new Uint8Array(x0),
      _51: x0 => new Uint8ClampedArray(x0),
      _53: x0 => new Int16Array(x0),
      _55: x0 => new Uint16Array(x0),
      _57: x0 => new Int32Array(x0),
      _59: x0 => new Uint32Array(x0),
      _61: x0 => new Float32Array(x0),
      _63: x0 => new Float64Array(x0),
      _74: Date.now,
      _76: s => new Date(s * 1000).getTimezoneOffset() * 60,
      _78: () => {
        let stackString = new Error().stack.toString();
        let frames = stackString.split('\n');
        let drop = 2;
        if (frames[0] === 'Error') {
            drop += 1;
        }
        return frames.slice(drop).join('\n');
      },
      _79: () => typeof dartUseDateNowForTicks !== "undefined",
      _80: () => 1000 * performance.now(),
      _81: () => Date.now(),
      _99: s => JSON.stringify(s),
      _100: s => printToConsole(s),
      _108: (string, times) => string.repeat(times),
      _109: Function.prototype.call.bind(String.prototype.indexOf),
      _111: (string, token) => string.split(token),
      _123: a => a.length,
      _125: (a, i) => a[i],
      _126: (a, i, v) => a[i] = v,
      _129: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
      _130: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
      _131: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
      _132: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
      _133: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
      _134: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
      _135: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
      _138: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
      _139: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
      _140: (t, s) => t.set(s),
      _142: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
      _144: o => o.buffer,
      _145: o => o.byteOffset,
      _146: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
      _147: (b, o) => new DataView(b, o),
      _148: (b, o, l) => new DataView(b, o, l),
      _149: Function.prototype.call.bind(DataView.prototype.getUint8),
      _150: Function.prototype.call.bind(DataView.prototype.setUint8),
      _151: Function.prototype.call.bind(DataView.prototype.getInt8),
      _152: Function.prototype.call.bind(DataView.prototype.setInt8),
      _153: Function.prototype.call.bind(DataView.prototype.getUint16),
      _154: Function.prototype.call.bind(DataView.prototype.setUint16),
      _155: Function.prototype.call.bind(DataView.prototype.getInt16),
      _156: Function.prototype.call.bind(DataView.prototype.setInt16),
      _157: Function.prototype.call.bind(DataView.prototype.getUint32),
      _158: Function.prototype.call.bind(DataView.prototype.setUint32),
      _159: Function.prototype.call.bind(DataView.prototype.getInt32),
      _160: Function.prototype.call.bind(DataView.prototype.setInt32),
      _165: Function.prototype.call.bind(DataView.prototype.getFloat32),
      _166: Function.prototype.call.bind(DataView.prototype.setFloat32),
      _167: Function.prototype.call.bind(DataView.prototype.getFloat64),
      _168: Function.prototype.call.bind(DataView.prototype.setFloat64),
      _185: o => Object.keys(o),
      _186: (ms, c) =>
      setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
      _190: (c) =>
      queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
      _212: (x0,x1,x2) => x0.postMessage(x1,x2),
      _213: x0 => x0.close(),
      _214: () => new MessageChannel(),
      _215: (x0,x1) => x0.push(x1),
      _226: () => globalThis.self,
      _227: x0 => x0.close(),
      _228: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._228(f,arguments.length,x0) }),
      _229: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._229(f,arguments.length,x0) }),
      _230: (x0,x1,x2) => x0.postMessage(x1,x2),
      _231: (x0,x1) => x0.postMessage(x1),
      _236: (x0,x1) => globalThis.Object.is(x0,x1),
      _237: (x0,x1) => x0.at(x1),
      _238: x0 => x0.entries(),
      _239: x0 => x0.values(),
      _240: x0 => globalThis.BigInt(x0),
      _241: () => new Map(),
      _242: (x0,x1,x2) => x0.set(x1,x2),
      _243: () => new Set(),
      _244: (x0,x1) => x0.add(x1),
      _245: x0 => x0.toString(),
      _246: x0 => x0.length,
      _248: x0 => x0.buffer,
      _261: (s, m) => {
        try {
          return new RegExp(s, m);
        } catch (e) {
          return String(e);
        }
      },
      _262: (x0,x1) => x0.exec(x1),
      _266: o => o === undefined,
      _268: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
      _270: o => {
        const proto = Object.getPrototypeOf(o);
        return proto === Object.prototype || proto === null;
      },
      _271: o => o instanceof RegExp,
      _272: (l, r) => l === r,
      _273: o => o,
      _274: o => o,
      _275: o => o,
      _276: b => !!b,
      _277: o => o.length,
      _279: (o, i) => o[i],
      _280: f => f.dartFunction,
      _281: () => ({}),
      _282: () => [],
      _284: () => globalThis,
      _287: (o, p) => o[p],
      _288: (o, p, v) => o[p] = v,
      _289: (o, m, a) => o[m].apply(o, a),
      _291: o => String(o),
      _293: o => {
        if (o === undefined) return 1;
        var type = typeof o;
        if (type === 'boolean') return 2;
        if (type === 'number') return 3;
        if (type === 'string') return 4;
        if (o instanceof Array) return 5;
        if (ArrayBuffer.isView(o)) {
          if (o instanceof Int8Array) return 6;
          if (o instanceof Uint8Array) return 7;
          if (o instanceof Uint8ClampedArray) return 8;
          if (o instanceof Int16Array) return 9;
          if (o instanceof Uint16Array) return 10;
          if (o instanceof Int32Array) return 11;
          if (o instanceof Uint32Array) return 12;
          if (o instanceof Float32Array) return 13;
          if (o instanceof Float64Array) return 14;
          if (o instanceof DataView) return 15;
        }
        if (o instanceof ArrayBuffer) return 16;
        return 17;
      },
      _294: o => [o],
      _295: (o0, o1) => [o0, o1],
      _296: (o0, o1, o2) => [o0, o1, o2],
      _297: (o0, o1, o2, o3) => [o0, o1, o2, o3],
      _302: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _308: x0 => new ArrayBuffer(x0),
      _313: x0 => x0.flags,
      _320: (o, p) => o[p],
      _323: x0 => x0.random(),
      _326: () => globalThis.Math,
      _327: Function.prototype.call.bind(Number.prototype.toString),
      _328: Function.prototype.call.bind(BigInt.prototype.toString),
      _329: Function.prototype.call.bind(Number.prototype.toString),
      _2699: x0 => x0.port1,
      _2700: x0 => x0.port2,
      _2703: (x0,x1) => x0.onmessage = x1,
      _2760: (x0,x1) => x0.onmessage = x1,

    };

    const baseImports = {
      dart2wasm: dart2wasm,
      Math: Math,
      Date: Date,
      Object: Object,
      Array: Array,
      Reflect: Reflect,
            s: [
        "Attempt to execute code removed by Dart AOT compiler (TFA)",
"Could not call main",
"null",
"",
" (",
")",
": ",
"Instance of '",
"'",
"Object?",
"Object",
"dynamic",
"void",
"Invalid top type kind",
"Invalid argument",
"(s)",
"0.0",
"-0.0",
"1.0",
"-1.0",
"NaN",
"-Infinity",
"Infinity",
"e",
".0",
"Infinity or NaN toInt",
"Unsupported operation: ",
"RangeError (details omitted due to --minify)",
"minified:Class",
"<",
", ",
">",
"?",
"T",
"true",
"false",
"JavaScriptError",
"[",
"]",
"...",
"Runtime type check failed (details omitted due to --minify)",
"Type parameter should have been substituted already.",
"Type argument substitution not supported for ",
"X",
" extends ",
"(",
"{",
"}",
" => ",
"Closure: ",
" ",
"FutureOr",
"required ",
"Null check operator used on a null value",
"IndexError (details omitted due to --minify)",
"Concurrent modification during iteration: ",
".",
"Unhandled dartifyRaw type case: ",
"{...}",
"Division resulted in non-finite value",
"IntegerDivisionByZeroException",
"Type '",
"' is not a subtype of type '",
" in type cast",
"Expected integer value, but was not integer.",
"push",
"(...)",
"MapEntry(",
"Function?",
"Function",
"buffer",
"start",
"Invalid value",
": Not greater than or equal to ",
": Not in inclusive range ",
"..",
": Valid value range is empty",
": Only valid value is ",
"RangeError",
"Too few elements",
"Bad state: ",
"index",
"Index out of range",
": index must not be negative",
": no indices are valid",
": index should be less than ",
"0",
"00000000",
"0000",
"00",
"-",
"byteOffset",
"_lastQuoRemDigits",
"Field '",
"' has not been initialized.",
"LateInitializationError: ",
"_lastRemUsed",
"_lastQuoRemUsed",
"bigInt",
"Must be a platform BigInt",
"shift-amount must be positive ",
"_lastRem_nsh",
"squadronJsify",
"Local '",
"' has already been initialized.",
"getPrototypeOf",
"Int8Array",
"ArrayBuffer",
"MessagePort",
"ReadableStream",
"WritableStream",
"TransformStream",
"ImageBitmap",
"VideoFrame",
"OffscreenCanvas",
"RTCDataChannel",
"MediaSourceHandle",
"MIDIAccess",
":",
"The implementation cannot handle very large operands (was: ",
").",
"Exception: ",
",",
"Z",
"000",
"Null",
"Never",
"Too few arguments passed. Expected 1 or more, got ",
" instead.",
"Field '_initialization' has already been initialized.",
"Cannot complete a future with itself",
"The error handler of Future.then must return a value of the returned future's type",
"onError",
"The error handler of Future.catchError must return a value of the future's type",
"Error handler must accept one Object or one Object and a StackTrace as arguments, and return a value of the returned future's type",
"Future already completed",
"Missing client for connection request",
"Connection request expected",
"Already connected",
"AA==",
"NoSuchMethodError: method not found: '",
"'\n",
"Receiver: ",
"\n",
"Arguments: [",
"Symbol(\"",
"\")",
"s",
"@",
"=",
"IntegerDivisionByZeroException._stackTrace",
"AQ==",
"Worker termination failed with error: ",
"Failed to post response: ",
"Failed to post response ",
"$#",
"Converting object to an encodable object failed:",
"Converting object did not return an encodable object:",
"Ag==",
"Cyclic error in JSON stringify",
"\"",
"{}",
",\"",
"\":",
"$T",
"$C",
"$C*",
"error",
"all",
"Log events cannot have Level.all",
"off",
"nothing",
"Log events cannot have Level.off",
"Level.",
"Invalid command identifier",
" in service operations map: ",
". Command ids must be positive.",
"Field 'operations' has been assigned during initialization.",
"Instance check should not reach function type parameter.",
"TypeError: ",
" is not a subtype of ",
"Cannot modify an unmodifiable list",
"Web Assembly",
"wasm",
"JavaScript",
"js",
"SquadronPlatformType.",
"Division by zero",
"Not coprime",
"No events after a done.",
"Cannot add event after closing",
"Cannot add event while adding a stream",
"error #",
"computation",
"The type parameter is not nullable",
"controller",
"Frequency is too high!",
"7.1.2",
"Aw==",
"Deferred message failed with error: ",
"Type argument '",
"' is not a ",
"subtype of type parameter bound '",
"???",
"type '",
"' is not a subtype of ",
"' of '",
"$!",
"BA==",
"BQ==",
"Bg==",
"K",
"V",
"Connection failed: ",
"Invalid worker request",
"Array",
"Map",
"Set",
"length",
"Could not parse BigInt",
"FormatException",
" (at line ",
", character ",
")\n",
" (at character ",
"^\n",
"^\\s*([+-]?)((0x[a-f0-9]+)|(\\d+)|([a-z0-9]+))\\s*$",
"m",
"i",
"u",
"g",
"Illegal RegExp pattern (",
"RegExp/",
"/",
"bigint",
"value",
"done",
"next",
"squadronDartify",
"data",
"Unexpected connection request: ",
"Worker service is not ready",
"Missing client for request: ",
"Unknown command: ",
"Unhandled error: ",
"Service uninstallation failed with error: ",
"handleError callback must take either an Object (the error), or both an Object (the error) and a StackTrace.",
"Stream has already been listened to.",
"streamId",
"subscription",
"Token reference mismatch",
"Cancelation token mismatch",
"trace",
"Terminating Web Worker",
"Intentional failure"
      ],

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
      "fromCharCodeArray": (a, start, end) => {
        if (end <= start) return '';

        const read = dartInstance.exports.$wasmI16ArrayGet;
        let result = '';
        let index = start;
        const chunkLength = Math.min(end - index, 500);
        let array = new Array(chunkLength);
        while (index < end) {
          const newChunkLength = Math.min(end - index, 500);
          for (let i = 0; i < newChunkLength; i++) {
            array[i] = read(a, index++);
          }
          if (newChunkLength < chunkLength) {
            array = array.slice(0, newChunkLength);
          }
          result += String.fromCharCode(...array);
        }
        return result;
      },
      "intoCharCodeArray": (s, a, start) => {
        if (s == '') return 0;

        const write = dartInstance.exports.$wasmI16ArraySet;
        for (var i = 0; i < s.length; ++i) {
          write(a, start++, s.charCodeAt(i));
        }
        return s.length;
      },
    };


    

    dartInstance = await WebAssembly.instantiate(this.module, {
      ...baseImports,
      ...additionalImports,
      
      "wasm:js-string": jsStringPolyfill,
    });

    return new InstantiatedApp(this, dartInstance);
  }
}

class InstantiatedApp {
  constructor(compiledApp, instantiatedModule) {
    this.compiledApp = compiledApp;
    this.instantiatedModule = instantiatedModule;
  }

  // Call the main function with the given arguments.
  invokeMain(...args) {
    this.instantiatedModule.exports.$invokeMain(args);
  }
}
