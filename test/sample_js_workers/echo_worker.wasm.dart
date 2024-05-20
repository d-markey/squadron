import 'dart:js_interop';

import 'package:web/web.dart' as web;

// this is a regular Web worker

@JS()
external web.DedicatedWorkerGlobalScope get self;

void main() {
  final scope = self;
  scope.onmessage = (web.MessageEvent e) {
    try {
      scope.postMessage('ECHO "${e.data.dartify()}"'.jsify());
    } catch (error) {
      scope.postMessage('Error in Web Worker main program: $error'.jsify());
    }
  }.toJS;
}
