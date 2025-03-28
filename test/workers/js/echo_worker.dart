// ignore: deprecated_member_use
import 'dart:html';

import 'package:squadron/src/worker/worker_response.dart';

// this is a regular Web Worker with legacy dart:html library

void main() {
  final scope = DedicatedWorkerGlobalScope.instance;
  scope.onMessage.listen((MessageEvent e) {
    scope.postMessage('ECHO "${e.data}"');
  });
  // post a message indicating that the Web worker is up and running
  scope.postMessage(WorkerResponse.ready().wrapInPlace());
}
