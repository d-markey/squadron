// ignore_for_file: file_names

@TestOn('browser && dart2js')
library;

import 'dart:async';
import 'dart:html' as web show Worker;
import 'dart:html' hide Worker;

import 'package:squadron/src/_impl/web/entry_point_uri.dart';
import 'package:squadron/src/exceptions/squadron_error.dart';
import 'package:squadron/src/worker/worker_response.dart';
import 'package:test/test.dart';

import 'classes/test_context.dart';
import 'classes/utils.dart';

void main() async {
  final testContext = await TestContext.init('');
  execute(testContext);
}

String testScript = '01_web_worker_js_test.dart';

void execute(TestContext tc) {
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
