@TestOn('browser && dart2wasm')
library;

import 'dart:async';
import 'dart:js_interop';

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

          final errorHandler = (JSAny? event) {
            final err = _errorFromEvent(event);
            completer.completeError(err);
            ready.completeError(err);
          }.toJS;

          worker.onerror = errorHandler;
          worker.onmessageerror = errorHandler;

          // instal handler waiting for ready signal
          worker.onmessage = (MessageEvent e) {
            final msg = getMessageEventData('worker.onmessage', e);
            final resp = WorkerResponseExt.from(msg);
            try {
              ready.complete(resp.result);
            } catch (error) {
              ready.completeError(error);
            }
          }.toJS;

          final ok = await ready.future;
          expect(ok, isTrue);

          // ready: now instal message handler
          worker.onmessage = (MessageEvent e) {
            getMessageEventData('worker.onmessage', e);
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
            getMessageEventData('worker.onmessage', e);
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
            getErrorEventError('errorHandler', event);
            final err = _errorFromEvent(event);
            completer.completeError(err);
          }.toJS;

          worker.onerror = errorHandler;
          worker.onmessageerror = errorHandler;

          worker.onmessage = (MessageEvent e) {
            try {
              final msg = e.data.dartify();
              if (msg is List && !connected) {
                final err = WorkerResponseExt.from(msg).error;
                if (err != null) throw err;
                connected = true;
                return;
              }
              completer.complete(msg.toString());
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
            getErrorEventError('errorHandler', event);
            final err = _errorFromEvent(event);
            completer.completeError(err);
          }.toJS;

          worker.onerror = errorHandler;
          worker.onmessageerror = errorHandler;

          worker.onmessage = (MessageEvent e) {
            getMessageEventData('worker.onmessage', e);
            try {
              final msg = e.data.dartify();
              if (msg is List && !connected) {
                final err = WorkerResponseExt.from(msg).error;
                if (err != null) throw err;
                connected = true;
                return;
              }
              completer.complete(msg.toString());
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
