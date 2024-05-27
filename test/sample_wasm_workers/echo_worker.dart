import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart';

// this is a regular Web worker

@JS()
external DedicatedWorkerGlobalScope get self;

void main() {
  final scope = self;
  console.log(
      'starting echo_worker with scope = $scope #${(scope as JSObject)['sqId']}...'
          .jsify());
  scope.onerror = (JSAny? e) {
    console.log('error $e in echo_worker'.jsify());
  }.toJS;
  scope.onmessageerror = (JSAny? e) {
    console.log('message error $e in echo_worker'.jsify());
  }.toJS;
  scope.onmessage = (MessageEvent? e) {
    try {
      console.log('message $e in echo_worker'.jsify());
      final data = e?.data.dartify();
      scope.postMessage('ECHO "$data"'.jsify());
    } catch (error) {
      scope.postMessage('Error in Web Worker main program: $error'.jsify());
    }
  }.toJS;
  console.log('echo_worker ready'.jsify());
  scope.postMessage(true.jsify());
}
