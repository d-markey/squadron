import 'dart:js_interop';

import 'package:squadron/src/worker/worker_response.dart';
import 'package:web/web.dart';

// this is a regular Web Worker

@JS()
external DedicatedWorkerGlobalScope get self;

void main() {
  final scope = self;
  scope.onmessage = (MessageEvent? e) {
    final data = e?.data.dartify();
    scope.postMessage('ECHO "$data"'.toJS);
  }.toJS;
  // post a message indicating that the Web worker is up and running
  scope.postMessage(WorkerResponse.ready().wrapInPlace().jsify());
}
