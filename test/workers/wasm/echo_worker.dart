import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart';

// this is a regular Web Worker

@JS()
external DedicatedWorkerGlobalScope get self;

void main() {
  final scope = self;
  console.log(
      'starting echo_worker with scope = $scope #${(scope as JSObject)['sqId']}...'
          .jsify());
  scope.onerror = (JSAny? e) {
    console.log('error $e in echo_worker'.toJS);
  }.toJS;
  scope.onmessageerror = (JSAny? e) {
    console.log('message error $e in echo_worker'.toJS);
  }.toJS;
  scope.onmessage = (MessageEvent? e) {
    try {
      console.log('message $e in echo_worker'.toJS);
      final data = e?.data.dartify();
      scope.postMessage('ECHO "$data"'.toJS);
    } catch (error) {
      scope.postMessage('Error in Web Worker main program: $error'.toJS);
    }
  }.toJS;
  console.log('echo_worker ready'.toJS);
  // post a message indicating that the Web worker is up and running
  scope.postMessage({"ready": true}.jsify());
}
