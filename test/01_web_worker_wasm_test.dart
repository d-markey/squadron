// ignore_for_file: file_names

@TestOn('browser && dart2wasm')
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:squadron/src/_impl/web/entry_point_uri.dart';
import 'package:squadron/src/exceptions/squadron_error.dart';
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

String testScript = '01_web_worker_wasm_test.dart';

void execute(TestContext tc) {
  tc.run(() {
    tc.group("- WebWorker", () {
      tc.test('- plain Web Worker', () async {
        final ep = EntryPointUri.from(tc.entryPoints.native!);
        final w = web.Worker(ep.uri.toJS);

        try {
          final res = Completer<String>();
          w.onerror = w.onmessageerror = (ErrorEvent e) {
            res.completeError(_errorFromEvent(e));
          }.toJS;
          w.onmessage = (MessageEvent e) {
            try {
              res.complete(e.data?.dartify().toString());
            } catch (ex) {
              res.completeError(ex);
            }
          }.toJS;

          w.postMessage('Hello'.toJS);
          expect(await res.future, 'ECHO "Hello"');
        } finally {
          ep.release();
          w.terminate();
        }
      });

      tc.test('- plain Web Worker (in-memory)', () async {
        final ep = EntryPointUri.from(tc.entryPoints.inMemory!);
        final w = web.Worker(ep.uri.toJS);

        try {
          final res = Completer<String>();
          w.onerror = w.onmessageerror = (ErrorEvent e) {
            res.completeError(_errorFromEvent(e));
          }.toJS;
          w.onmessage = (MessageEvent e) {
            try {
              res.complete(e.data?.dartify().toString());
            } catch (ex) {
              res.completeError(ex);
            }
          }.toJS;

          w.postMessage('Hello'.toJS);
          expect(await res.future, 'ECHO "Hello"');
        } finally {
          ep.release();
          w.terminate();
        }
      });

      tc.test('- regular Web Worker', () async {
        final ep = EntryPointUri.from(tc.entryPoints.echo!);
        final w = web.Worker(ep.uri.toJS);

        try {
          final ready = Completer<bool>();
          final res = Completer<String>();
          w.onerror = w.onmessageerror = (ErrorEvent e) {
            final err = _errorFromEvent(e);
            ready.completeError(err);
            res.completeError(err);
          }.toJS;
          w.onmessage = (MessageEvent e) {
            if (!ready.isCompleted) {
              final status = WorkerResponseExt.from(e.data.dartify() as List);
              ready.complete(status.result);
            } else {
              res.complete(e.data.dartify()?.toString() ?? '');
            }
          }.toJS;

          // wait for worker to be ready before using it
          expect(await ready.future, isTrue);
          w.postMessage('Hello'.toJS);
          expect(await res.future, 'ECHO "Hello"');
        } finally {
          ep.release();
          w.terminate();
        }
      });

      tc.test('- missing Web Worker (JavaScript)', () async {
        final ep = EntryPointUri.from(Uri.parse('not_found.js'));
        final w = web.Worker(ep.uri.toJS);

        try {
          final res = Completer<String>();
          w.onerror = w.onmessageerror = (ErrorEvent e) {
            res.completeError(_errorFromEvent(e));
          }.toJS;
          w.onmessage = (MessageEvent e) {
            res.complete('handled $e');
          }.toJS;

          w.postMessage('Hello'.toJS);
          await expectLater(res.future, failsWith<SquadronError>());
        } finally {
          ep.release();
          w.terminate();
        }
      });

      tc.test('- missing Web Worker (WebAssembly)', () async {
        final ep = EntryPointUri.from(Uri.parse('not_found.wasm'));
        final w = web.Worker(ep.uri.toJS);

        try {
          final res = Completer<String>();
          w.onerror = w.onmessageerror = (ErrorEvent e) {
            res.completeError(_errorFromEvent(e));
          }.toJS;
          w.onmessage = (MessageEvent e) {
            res.complete('handled $e');
          }.toJS;

          w.postMessage('Hello'.toJS);
          await expectLater(res.future, failsWith<SquadronError>());
        } finally {
          ep.release();
          w.terminate();
        }
      });
    });
  });
}

SquadronError _errorFromEvent(JSAny? event) {
  String msg;
  if (event.isA<ErrorEvent>()) {
    try {
      msg = (event as ErrorEvent).message;
    } catch (_) {
      msg = 'Unknown error';
    }
  } else {
    msg = 'Unknown error: ${event.dartify()}';
  }
  return SquadronErrorExt.create(msg);
}
