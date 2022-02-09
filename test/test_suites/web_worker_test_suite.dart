import 'dart:async';
import 'dart:html' as browser;

import 'package:test/test.dart';

import '../classes/worker_entry_points.dart';

void webWorkerTests() {
  test('classic Web worker', () async {
    final worker = browser.Worker(getEntryPoint('echo'));
    expect(worker, isNotNull);
    final completer = Completer<String>();
    worker.onError.listen((error) {
      completer.complete(error.toString());
    });
    worker.onMessage.listen((browser.MessageEvent e) {
      try {
        completer.complete(e.data);
      } catch (error) {
        completer.complete(error.toString());
      }
    });
    worker.postMessage('Hello');
    var res = await completer.future;
    expect(res, 'ECHO "Hello"');
    worker.terminate();
  });
}
