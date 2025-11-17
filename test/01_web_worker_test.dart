// ignore_for_file: file_names

@TestOn('dart2js || dart2wasm')
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:squadron/src/_impl/web/_entry_point_uri.dart';
import 'package:squadron/src/_impl/xplat/_disconnected_channel.dart';
import 'package:squadron/src/exceptions/squadron_error.dart';
import 'package:squadron/src/worker/worker_response.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web show Worker;
import 'package:web/web.dart' hide Worker;

import 'src/test_context.dart';
import 'src/utils.dart';

Future<void> main() => TestContext.run(execute);

const testScript = '01_web_worker_test.dart';

void execute(TestContext? tc) {
  if (tc == null) return;

  tc.launch(() {
    tc.group('- WEB WORKER', () {
      tc.test('- Add random hash - without version', () {
        final webEntryPoint = EntryPointUri.from(
          Uri.parse('test/worker.js'),
          addRandomHash: true,
        );
        expect(webEntryPoint.uri, contains('?h='));
        final uri = Uri.parse(webEntryPoint.uri);
        expect(uri.path, 'test/worker.js');
        expect(uri.queryParameters, hasLength(1));
        expect(uri.queryParameters.keys, contains('h'));
        expect(int.tryParse(uri.queryParameters['h']!), isNotNull);
      });

      tc.test('- Add random hash - with version', () {
        final webEntryPoint = EntryPointUri.from(
          Uri.parse('test/worker.js?v=1'),
          addRandomHash: true,
        );
        expect(webEntryPoint.uri, contains('?v=1&h='));
        final uri = Uri.parse(webEntryPoint.uri);
        expect(uri.path, 'test/worker.js');
        expect(uri.queryParameters, hasLength(2));
        expect(uri.queryParameters.keys, contains('v'));
        expect(uri.queryParameters['v'], '1');
        expect(uri.queryParameters.keys, contains('h'));
        expect(int.tryParse(uri.queryParameters['h']!), isNotNull);
      });

      tc.test('- JavaScript Web Worker', () async {
        final ep =
            EntryPointUri.from(tc.entryPoints.native!, addRandomHash: true);
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

      tc.test('- JavaScript Web Worker (in-memory)', () async {
        final ep =
            EntryPointUri.from(tc.entryPoints.inMemory!, addRandomHash: true);
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

      tc.test('- Dart Web Worker', () async {
        final ep =
            EntryPointUri.from(tc.entryPoints.echo!, addRandomHash: true);
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
              final status = WorkerResponseImpl.from(e.data.dartify() as List);
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

      tc.test('- Missing Web Worker (JavaScript)', () async {
        final ep =
            EntryPointUri.from(Uri.parse('not_found.js'), addRandomHash: false);
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

      tc.test('- Missing Web Worker (WebAssembly)', () async {
        final ep = EntryPointUri.from(Uri.parse('not_found.wasm'),
            addRandomHash: false);
        final w = web.Worker(ep.uri.toJS);

        try {
          final completer = Completer<String>();
          w.onerror = w.onmessageerror = (ErrorEvent e) {
            completer.completeError(_errorFromEvent(e));
          }.toJS;
          w.onmessage = (MessageEvent e) {
            try {
              final res = WorkerResponseImpl.from(e.data.dartify() as List);
              if (res.unwrapInPlace(DisconnectedChannel())) {
                final error = res.error;
                if (error != null) {
                  completer.completeError(error);
                } else {
                  completer.complete(res.result.toString());
                }
              }
            } catch (ex) {
              completer.completeError(Exception('Unexpected: $ex'));
            }
          }.toJS;

          w.postMessage('Hello'.toJS);
          try {
            final res = await completer.future;
            throw unexpectedSuccess('postMessage', res);
          } on SquadronError catch (ex) {
            expect(ex, reports('Failed to load Web Worker'));
            expect(ex, reports('not_found.wasm'));
          }
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
  return SquadronErrorImpl.create(msg);
}
