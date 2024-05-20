import 'dart:js_interop';

import 'package:web/web.dart';

// this is a regular Web worker

@JS()
external DedicatedWorkerGlobalScope get self;

void main() {
  final scope = self;
  scope.onmessage = (MessageEvent e) {
    try {
      final data = e.data?.dartify();
      scope.postMessage('ECHO "$data"'.jsify());
    } catch (error) {
      scope.postMessage('Error in Web Worker main program: $error'.jsify());
    }
  }.toJS;
}
