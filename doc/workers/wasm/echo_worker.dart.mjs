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
            _37: x0 => new Array(x0),
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
      _99: s => JSON.stringify(s),
      _100: s => printToConsole(s),
      _108: (string, times) => string.repeat(times),
      _109: Function.prototype.call.bind(String.prototype.indexOf),
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
      _190: (c) =>
      queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
      _208: () => globalThis.self,
      _209: (x0,x1) => x0.postMessage(x1),
      _210: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._210(f,arguments.length,x0) }),
      _263: o => o === undefined,
      _265: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
      _267: o => {
        const proto = Object.getPrototypeOf(o);
        return proto === Object.prototype || proto === null;
      },
      _269: (l, r) => l === r,
      _270: o => o,
      _271: o => o,
      _272: o => o,
      _273: b => !!b,
      _274: o => o.length,
      _276: (o, i) => o[i],
      _277: f => f.dartFunction,
      _278: () => ({}),
      _279: () => [],
      _284: (o, p) => o[p],
      _285: (o, p, v) => o[p] = v,
      _286: (o, m, a) => o[m].apply(o, a),
      _288: o => String(o),
      _290: o => {
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
      _305: x0 => new ArrayBuffer(x0),
      _320: x0 => x0.random(),
      _323: () => globalThis.Math,
      _324: Function.prototype.call.bind(Number.prototype.toString),
      _325: Function.prototype.call.bind(BigInt.prototype.toString),
      _326: Function.prototype.call.bind(Number.prototype.toString),
      _2666: x0 => x0.data,
      _2759: (x0,x1) => x0.onmessage = x1,

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
"Concurrent modification during iteration: ",
".",
"Unhandled dartifyRaw type case: ",
"{...}",
"push",
"Type '",
"' is not a subtype of type '",
" in type cast",
"(...)",
"Division resulted in non-finite value",
"IntegerDivisionByZeroException",
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
"-",
"0",
":",
"The implementation cannot handle very large operands (was: ",
").",
"Exception: ",
",",
"Z",
"00",
"000",
"Null",
"Never",
"Too few arguments passed. Expected 1 or more, got ",
" instead.",
"ECHO \"",
"\"",
"length"
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
