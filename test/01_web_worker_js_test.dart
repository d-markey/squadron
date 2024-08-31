// ignore_for_file: file_names

@TestOn('browser && dart2js')
library;

import 'dart:async';
import 'dart:html' as web show Worker;
import 'dart:html' hide Worker;

import 'package:squadron/src/_impl/web/_entry_point_uri.dart';
import 'package:squadron/src/_impl/xplat/_disconnected_channel.dart';
import 'package:squadron/src/exceptions/squadron_error.dart';
import 'package:squadron/src/worker/worker_response.dart';
import 'package:test/test.dart';

import 'classes/test_context.dart';
import 'classes/utils.dart';

void main() {
  TestContext.init('').then(execute);
  // TestContext.init('', TestPlatform.wasm).then(execute);
}

String testScript = '01_web_worker_js_test.dart';

void execute(TestContext? tc) {
  if (tc == null) return;

  tc.run(() {
    tc.group("- WebWorker", () {
      tc.test('- plain Web Worker', () async {
        final ep = EntryPointUri.from(tc.entryPoints.native!);
        final w = web.Worker(ep.uri);

        try {
          final res = Completer<String>();
          w.onError.listen((e) => res.completeError(_errorFromEvent(e)));
          w.onMessage.listen((e) => res.complete(e.data));

          w.postMessage('Hello');
          expect(await res.future, 'ECHO "Hello"');
        } finally {
          ep.release();
          w.terminate();
        }
      });

      tc.test('- plain Web Worker (in-memory)', () async {
        final ep = EntryPointUri.from(tc.entryPoints.inMemory!);
        final w = web.Worker(ep.uri);

        try {
          final res = Completer<String>();
          w.onError.listen((e) => res.completeError(_errorFromEvent(e)));
          w.onMessage.listen((e) => res.complete(e.data));

          w.postMessage('Hello');
          expect(await res.future, 'ECHO "Hello"');
        } finally {
          ep.release();
          w.terminate();
        }
      });

      tc.test('- regular Web Worker', () async {
        final ep = EntryPointUri.from(tc.entryPoints.echo!);
        final w = web.Worker(ep.uri);

        try {
          final ready = Completer<bool>();
          final res = Completer<String>();
          w.onError.listen((e) {
            final err = _errorFromEvent(e);
            ready.completeError(err);
            res.completeError(err);
          });
          w.onMessage.listen((MessageEvent e) {
            if (!ready.isCompleted) {
              ready.complete(WorkerResponseExt.from(e.data as List).result);
            } else {
              res.complete(e.data?.toString() ?? '');
            }
          });

          // wait for worker to be ready before using it
          expect(await ready.future, isTrue);
          w.postMessage('Hello');
          expect(await res.future, 'ECHO "Hello"');
        } finally {
          ep.release();
          w.terminate();
        }
      });

      tc.test('- missing Web Worker (JavaScript)', () async {
        final ep = EntryPointUri.from(Uri.parse('not_found.js'));
        final w = web.Worker(ep.uri);

        try {
          final res = Completer<String>();
          w.onError.listen((e) => res.completeError(_errorFromEvent(e)));
          w.onMessage.listen((e) => res.complete('handled $e'));

          w.postMessage('Hello');
          await expectLater(res.future, failsWith<SquadronError>());
        } finally {
          ep.release();
          w.terminate();
        }
      });

      tc.test('- missing Web Worker (WebAssembly)', () async {
        final ep = EntryPointUri.from(Uri.parse('not_found.wasm'));
        final w = web.Worker(ep.uri);

        try {
          final completer = Completer<String>();
          w.onError.listen((e) => completer.completeError(_errorFromEvent(e)));
          w.onMessage.listen((e) {
            try {
              final res = WorkerResponseExt.from(e.data);
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
          });

          w.postMessage('Hello');
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

SquadronError _errorFromEvent(dynamic event) {
  String msg;
  if (event is ErrorEvent) {
    msg = event.message ?? 'Unknown error';
  } else {
    msg = 'Unknown error: $event';
  }
  return SquadronErrorExt.create(msg);
}
