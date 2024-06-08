@TestOn('browser && dart2js')
library;

import 'dart:async';
import 'dart:html' as web;

import 'package:test/test.dart';

import 'classes/test_context.dart';
import 'classes/utils.dart';

void main() async {
  final testContext = await TestContext.init('');
  execute(testContext);
}

Object _errorFromEvent(dynamic event) {
  if (event is web.ErrorEvent) {
    return event.error ?? Exception('Unknown error');
  } else {
    return event ?? Exception('Unknown error');
  }
}

void execute(TestContext testContext) {
  testContext.run(() {
    group("- WebWorker", () {
      test('- classic Web Worker', () async {
        final worker = web.Worker(testContext.entryPoints.echo!);
        expect(worker, isNotNull);

        final ready = Completer<bool>();
        final completer = Completer<String>();
        worker.onError.listen((event) {
          final err = _errorFromEvent(event);
          ready.completeError(err);
          completer.completeError(err);
        });

        // instal listener waiting for ready signal
        StreamSubscription? readySub;
        readySub = worker.onMessage.listen((web.MessageEvent e) {
          try {
            readySub!.cancel();
            ready.complete(e.data["ready"]);
          } catch (error) {
            ready.completeError(error);
          }
        });
        final ok = await ready.future;
        expect(ok, isTrue);

        // ready: now instal message handler
        worker.onMessage.listen((web.MessageEvent e) {
          try {
            completer.complete(e.data?.toString() ?? '');
          } catch (error) {
            completer.completeError(error);
          }
        });

        // everything is setup: worker can be used from now on
        worker.postMessage('Hello');
        final res = await completer.future;
        expect(res, equals('ECHO "Hello"'));
        worker.terminate();
      });

      test('- native Web Worker', () async {
        final worker = web.Worker(testContext.entryPoints.native!);
        expect(worker, isNotNull);

        final completer = Completer<String>();
        worker.onError.listen((event) {
          final err = _errorFromEvent(event);
          completer.completeError(err);
        });

        worker.onMessage.listen((web.MessageEvent e) {
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

      test('- in-memory Web Worker', () async {
        final worker = web.Worker(testContext.entryPoints.inMemory!);
        expect(worker, isNotNull);

        final completer = Completer<String>();
        worker.onError.listen((event) {
          final err = _errorFromEvent(event);
          completer.completeError(err);
        });

        worker.onMessage.listen((web.MessageEvent e) {
          try {
            completer.complete(e.data);
          } catch (error) {
            completer.completeError(error);
          }
        });

        worker.postMessage('Hello');
        var res = await completer.future;
        expect(res, equals('ECHO "Hello"'));
        worker.terminate();
      });

      test('- missing Web Worker', () async {
        final worker = web.Worker('not_found.js');
        expect(worker, isNotNull);

        final completer = Completer<String>();
        worker.onError.listen((event) {
          final err = _errorFromEvent(event);
          completer.completeError(err);
        });

        worker.onMessage.listen((web.MessageEvent e) {
          try {
            completer.complete(e.data);
          } catch (error) {
            completer.completeError(error);
          }
        });

        var success = true;
        try {
          worker.postMessage('Hello');
          final res = await completer.future;
          success = true;
          throw unexpectedSuccess('message processed by missing worker', res);
        } catch (ex) {
          if (success) {
            rethrow;
          }
        } finally {
          worker.terminate();
        }
      });
    });
  });
}
