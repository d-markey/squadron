@TestOn('browser && dart2wasm')
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:squadron/squadron.dart';
import 'package:squadron/src/_impl/web/_channel.dart';
import 'package:squadron/src/_impl/web/_patch.dart';
import 'package:squadron/src/worker/worker_response.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web show Worker;
import 'package:web/web.dart' hide Worker;

import 'classes/test_context.dart';
import 'classes/utils.dart';

void main() async {
  final testContext = await TestContext.init('');
  execute(testContext);
}

Object _errorFromEvent(JSAny? event) {
  if (event.isA<ErrorEvent>()) {
    return (event as ErrorEvent).error.dartify() ?? Exception('Unknown error');
  } else {
    return Exception('Unknown error: ${event.dartify()}');
  }
}

String testScript = 'web_worker_wasm_test.dart';

void execute(TestContext tc) {
  tc.run(() {
    tc.group("- WebWorker", () {
      tc.test('- native Web Worker', () async {
        final ep = getEntryPointUrl(tc.entryPoints.native!);
        final worker = web.Worker(ep.url);
        expect(worker, isNotNull);

        try {
          final completer = Completer<String>();

          final errorHandler = (JSAny? event) {
            final err = _errorFromEvent(event);
            completer.completeError(err);
          }.toJS;

          worker.onerror = errorHandler;
          worker.onmessageerror = errorHandler;

          worker.onmessage = (MessageEvent e) {
            try {
              completer.complete(e.data?.dartify().toString());
            } catch (error) {
              completer.completeError(error);
            }
          }.toJS;

          worker.postMessage('Hello'.toJS);
          var res = await completer.future;
          expect(res, equals('ECHO "Hello"'));
        } finally {
          if (ep.revoke) {
            URL.revokeObjectURL(ep.url);
          }
          worker.terminate();
        }
      });

      tc.test('- classic Web Worker', () async {
        final ep = getEntryPointUrl(tc.entryPoints.echo!);
        final worker = web.Worker(ep.url);
        expect(worker, isNotNull);

        try {
          final ready = Completer<bool>();
          final completer = Completer<String>();

          final errorHandler = (JSAny? e) {
            final err = _errorFromEvent(e);
            ready.completeError(err);
            completer.completeError(err);
          }.toJS;

          worker.onerror = errorHandler;
          worker.onmessageerror = errorHandler;

          // instal handler waiting for ready signal
          worker.onmessage = (MessageEvent e) {
            final status = WorkerResponseExt.from(e.data.dartify() as List);
            ready.complete(status.result);
          }.toJS;

          final ok = await ready.future;
          expect(ok, isTrue);

          // ready: now instal message handler
          worker.onmessage = (MessageEvent e) {
            completer.complete(e.data.dartify()?.toString() ?? '');
          }.toJS;

          // everything is setup: worker can be used from now on
          worker.postMessage('Hello'.toJS);
          final res = await completer.future;
          expect(res, equals('ECHO "Hello"'));
        } finally {
          if (ep.revoke) {
            URL.revokeObjectURL(ep.url);
          }
          worker.terminate();
        }
      });

      tc.test('- in-memory Web Worker', () async {
        final worker = web.Worker(tc.entryPoints.inMemory!.toString());
        expect(worker, isNotNull);

        try {
          final completer = Completer<String>();

          final errorHandler = (JSAny? event) {
            final err = _errorFromEvent(event);
            completer.completeError(err);
          }.toJS;

          worker.onerror = errorHandler;
          worker.onmessageerror = errorHandler;

          worker.onmessage = (MessageEvent e) {
            completer.complete(e.data?.dartify().toString());
          }.toJS;

          worker.postMessage('Hello'.toJS);
          var res = await completer.future;
          expect(res, equals('ECHO "Hello"'));
        } finally {
          worker.terminate();
        }
      });

      tc.test('- missing Web Worker (JavaScript)', () async {
        final ep = getEntryPointUrl(Uri.parse('not_found.js'));
        final worker = web.Worker(ep.url);
        expect(worker, isNotNull);

        var connected = false;
        try {
          final completer = Completer<String>();

          final errorHandler = (ErrorEvent event) {
            final err = _errorFromEvent(event);
            completer.completeError(err);
          }.toJS;

          worker.onerror = errorHandler;
          worker.onmessageerror = errorHandler;

          worker.onmessage = (MessageEvent e) {
            final data = getMessageEventData('worker.onmessage', e);
            print('processing $data');
            final res = WorkerResponseExt.from(data);
            if (!res.unwrapInPlace(ExceptionManager(), null)) return;
            if (res.error != null) {
              completer.completeError(res.error!);
            } else {
              completer.complete('processed message with result ${res.result}');
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
          }
        } finally {
          expect(connected, isFalse);
          if (ep.revoke) {
            URL.revokeObjectURL(ep.url);
          }
          worker.terminate();
        }
      });

      tc.test('- missing Web Worker (WebAssembly)', () async {
        final ep = getEntryPointUrl(Uri.parse('not_found.wasm'));
        final worker = web.Worker(ep.url);
        expect(worker, isNotNull);

        var connected = false;
        try {
          final completer = Completer<String>();

          final errorHandler = (ErrorEvent event) {
            final err = _errorFromEvent(event);
            completer.completeError(err);
          }.toJS;

          worker.onerror = errorHandler;
          worker.onmessageerror = errorHandler;

          worker.onmessage = (MessageEvent e) {
            final data = getMessageEventData('worker.onmessage', e);
            print('processing $data');
            final res = WorkerResponseExt.from(data);
            if (!res.unwrapInPlace(ExceptionManager(), null)) return;
            if (res.error != null) {
              completer.completeError(res.error!);
            } else {
              completer.complete('processed message with result ${res.result}');
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
          }
        } finally {
          expect(connected, isFalse);
          if (ep.revoke) {
            URL.revokeObjectURL(ep.url);
          }
          worker.terminate();
        }
      });
    });
  });
}
