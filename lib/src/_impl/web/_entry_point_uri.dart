import 'dart:js_interop';

import 'package:using/using.dart';
import 'package:web/web.dart' as web;

import '../../exceptions/squadron_error.dart';
import '../../typedefs.dart';
import '_platform.dart';
import '_typedefs.dart' as impl;

class EntryPointUri with Releasable {
  EntryPointUri._(this.uri, {required bool revoke}) : _revoke = revoke;

  final String uri;
  final bool _revoke;

  @override
  void release() {
    if (_revoke) {
      web.URL.revokeObjectURL(uri);
    }
    super.release();
  }

  factory EntryPointUri.from(EntryPoint workerEntrypoint,
      {required bool addRandomHash}) {
    workerEntrypoint as impl.EntryPoint;

    final fileName =
        workerEntrypoint.pathSegments.lastOrNull?.toString().toLowerCase() ??
            '';

    var url = workerEntrypoint.toString();
    if (fileName.endsWith('.js')) {
      // a JavaScript worker
      if (addRandomHash) url = _addRandomHash(url);
      return EntryPointUri._(url, revoke: false);
    } else if (fileName.endsWith('.wasm')) {
      // blob containing the JavaScript code to load and invoke the Web Assembly worker
      if (addRandomHash) url = _addRandomHash(url);
      final blob = web.Blob(
        [_wasmLoaderScript(url).toJS].toJS,
        web.BlobPropertyBag(type: 'application/javascript'),
      );
      return EntryPointUri._(web.URL.createObjectURL(blob), revoke: true);
    } else if (workerEntrypoint.isScheme('data') ||
        workerEntrypoint.isScheme('javascript')) {
      // something else, eg. inline JavaScript
      return EntryPointUri._(url, revoke: false);
    } else {
      throw SquadronErrorImpl.create('Invalid entry point URI');
    }
  }

  static String _addRandomHash(String url) {
    final hash = getRandomHash();
    return url.contains('?') ? '$url&h=$hash' : '$url?h=$hash';
  }

  static String _wasmLoaderScript(String url) => '''(async function(){
const workerUri=new URL("${url.replaceAll('"', '\\"')}",self.location.origin).href;
let newRt=false;
try{
  let d2w_rt; let worker;
  try{
    const wasm=fetch(workerUri);
    const rtUri=workerUri.replaceAll('.unopt','').replaceAll('.wasm','.mjs');
    d2w_rt=await import(rtUri);
    newRt=(typeof d2w_rt.compileStreaming==='function');
    worker=await(newRt
      ?(await d2w_rt.compileStreaming(wasm)).instantiate({})
      :d2w_rt.instantiate(WebAssembly.compileStreaming(wasm),{})
    );
  }catch(exception){
    console.error(
      `Failed to fetch and instantiate wasm module \${workerUri}: \${exception}\n`+
      "See https://dart.dev/web/wasm for more information."
    );
    throw new Error(exception.message??'Unknown error when instantiating worker module');
  }
  try{
    await (newRt?worker.invokeMain():d2w_rt.invoke(worker));
    //console.log(`Succesfully loaded and invoked \${workerUri}`);
  }catch(exception){
    console.error(`Exception while invoking wasm module \${workerUri}: \${exception}`);
    throw new Error(exception.message??'Unknown error when invoking worker module');
  }
}catch(ex){
  postMessage([null,null,["\$!",`Failed to load Web Worker from \${workerUri} (\${newRt?'new':'legacy'} runtime): \${ex}`,null,null],null,null]);
}
})()''';
}
