import 'dart:async';
import 'dart:html' as browser;

import 'package:test/test.dart';

import '../worker_services/worker_entry_points.dart';

void webWorkerTests() {
  setUp(() {
    // Squadron.logger = ConsoleSquadronLogger();
  });

  test('- classic Web worker', () async {
    final worker = browser.Worker(EntryPoints.echo);
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
    expect(res, equals('ECHO "Hello"'));
    worker.terminate();
  });

  test('- missing Web worker', () async {
    final worker = browser.Worker('not_found.js');
    expect(worker, isNotNull);
    final completer = Completer<String>();
    worker.onError.listen((error) {
      if (error is browser.ErrorEvent) {
        completer.complete('WORKER ERROR: ${error.message}');
      } else {
        completer.complete('WORKER ERROR: $error');
      }
    });
    worker.onMessage.listen((browser.MessageEvent e) {
      try {
        completer.complete(e.data);
      } catch (error) {
        completer.complete('ERROR: $error');
      }
    });
    worker.postMessage('Hello');
    var res = await completer.future;
    expect(res, contains('WORKER ERROR'));
    worker.terminate();
  });
}
