@TestOn('browser && dart2wasm')
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:test/test.dart';
import 'package:web/web.dart' as web;

import 'classes/test_context.dart';
import 'classes/utils.dart';

void main() async {
  final testContext = await TestContext.init('');
  execute(testContext);
}

Object _errorFromEvent(JSAny? event) {
  final e = event.dartify();
  if (e is web.ErrorEvent) {
    return e.error ?? Exception('Unknown error');
  } else {
    return e ?? Exception('Unknown error');
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

        final errorHandler = (JSAny? event) {
          final err = _errorFromEvent(event);
          completer.completeError(err);
          ready.completeError(err);
        }.toJS;

        worker.onerror = errorHandler;
        worker.onmessageerror = errorHandler;

        // instal handler waiting for ready signal
        worker.onmessage = (web.MessageEvent e) {
          try {
            ready.complete((e.data.dartify() as Map)["ready"]);
          } catch (error) {
            ready.completeError(error);
          }
        }.toJS;

        final ok = await ready.future;
        expect(ok, isTrue);

        // ready: now instal message handler
        worker.onmessage = (web.MessageEvent e) {
          try {
            completer.complete(e.data.dartify()?.toString() ?? '');
          } catch (error) {
            completer.completeError(error);
          }
        }.toJS;

        // everything is setup: worker can be used from now on
        worker.postMessage('Hello'.toJS);
        final res = await completer.future;
        expect(res, equals('ECHO "Hello"'));
        worker.terminate();
      });

      test('- native Web Worker', () async {
        final worker = web.Worker(testContext.entryPoints.native!);
        expect(worker, isNotNull);
        final completer = Completer<String>();

        final errorHandler = (JSAny? event) {
          final err = _errorFromEvent(event);
          completer.completeError(err);
        }.toJS;

        worker.onerror = errorHandler;
        worker.onmessageerror = errorHandler;

        worker.onmessage = (web.MessageEvent e) {
          try {
            completer.complete(e.data?.dartify().toString());
          } catch (error) {
            completer.completeError(error);
          }
        }.toJS;

        worker.postMessage('Hello'.toJS);
        var res = await completer.future;
        expect(res, equals('ECHO "Hello"'));
        worker.terminate();
      });

      test('- in-memory Web Worker', () async {
        final worker = web.Worker(testContext.entryPoints.inMemory!);
        expect(worker, isNotNull);
        final completer = Completer<String>();

        final errorHandler = (JSAny? event) {
          final err = _errorFromEvent(event);
          completer.completeError(err);
        }.toJS;

        worker.onerror = errorHandler;
        worker.onmessageerror = errorHandler;

        worker.onmessage = (web.MessageEvent e) {
          try {
            completer.complete(e.data?.dartify().toString());
          } catch (error) {
            completer.completeError(error);
          }
        }.toJS;

        worker.postMessage('Hello'.toJS);
        var res = await completer.future;
        expect(res, equals('ECHO "Hello"'));
        worker.terminate();
      });

      test('- missing Web Worker', () async {
        final worker = web.Worker('not_found.js');
        expect(worker, isNotNull);
        final completer = Completer<String>();

        final errorHandler = (JSAny? event) {
          final err = _errorFromEvent(event);
          completer.completeError(err);
        }.toJS;

        worker.onerror = errorHandler;
        worker.onmessageerror = errorHandler;

        worker.onmessage = (web.MessageEvent e) {
          try {
            completer.complete(e.data?.dartify().toString());
          } catch (error) {
            completer.completeError(error);
          }
        }.toJS;

        var success = false;
        try {
          worker.postMessage('Hello'.toJS);
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
