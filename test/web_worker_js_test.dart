@TestOn('browser && dart2js')
library;

import 'dart:async';
import 'dart:html' as web show Worker;
import 'dart:html' hide Worker;

import 'package:squadron/squadron.dart';
import 'package:squadron/src/_impl/web/_channel.dart';
import 'package:squadron/src/worker/worker_response.dart';
import 'package:test/test.dart';

import 'classes/test_context.dart';
import 'classes/utils.dart';

void main() async {
  final testContext = await TestContext.init('');
  execute(testContext);
}

Object _errorFromEvent(dynamic event) {
  if (event is ErrorEvent) {
    return event.error ?? Exception('Unknown error');
  } else {
    return Exception('Unknown error: $event');
  }
}

String testScript = 'web_worker_js_test.dart';

void execute(TestContext tc) {
  tc.run(() {
    tc.group("- WebWorker", () {
      tc.test('- native Web Worker', () async {
        final ep = getEntryPointUrl(tc.entryPoints.native!);
        final worker = web.Worker(ep.url);
        expect(worker, isNotNull);

        try {
          final completer = Completer<String>();
          worker.onError.listen((e) {
            final err = _errorFromEvent(e);
            completer.completeError(err);
          });

          worker.onMessage.listen((e) {
            completer.complete(e.data);
          });

          worker.postMessage('Hello');
          var res = await completer.future;
          expect(res, equals('ECHO "Hello"'));
        } finally {
          if (ep.revoke) {
            Url.revokeObjectUrl(ep.url);
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

          worker.onError.listen((e) {
            final err = _errorFromEvent(e);
            ready.completeError(err);
            completer.completeError(err);
          });

          // instal listener waiting for ready signal
          StreamSubscription? readySub;
          readySub = worker.onMessage.listen((MessageEvent e) {
            readySub!.cancel();
            final status = WorkerResponseExt.from(e.data as List);
            ready.complete(status.result);
          });
          final ok = await ready.future;
          expect(ok, isTrue);

          // ready: now instal message handler
          worker.onMessage.listen((MessageEvent e) {
            completer.complete(e.data?.toString() ?? '');
          });

          // everything is setup: worker can be used from now on
          worker.postMessage('Hello');
          final res = await completer.future;
          expect(res, equals('ECHO "Hello"'));
        } finally {
          if (ep.revoke) {
            Url.revokeObjectUrl(ep.url);
          }
          worker.terminate();
        }
      });

      tc.test('- in-memory Web Worker', () async {
        final worker = web.Worker(tc.entryPoints.inMemory!.toString());
        expect(worker, isNotNull);

        try {
          final completer = Completer<String>();
          worker.onError.listen((event) {
            final err = _errorFromEvent(event);
            completer.completeError(err);
          });

          worker.onMessage.listen((MessageEvent e) {
            completer.complete(e.data);
          });

          worker.postMessage('Hello');
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

          worker.onError.listen((event) {
            final err = _errorFromEvent(event);
            completer.completeError(err);
          });

          worker.onMessage.listen((MessageEvent e) {
            final data = e.data;
            final res = WorkerResponseExt.from(data);
            if (!res.unwrapInPlace(ExceptionManager(), null)) return;
            if (res.error != null) {
              completer.completeError(res.error!);
            } else {
              completer.complete('processed message with result ${res.result}');
            }
          });

          var success = false;
          try {
            worker.postMessage('Hello');
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
            Url.revokeObjectUrl(ep.url);
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

          worker.onError.listen((event) {
            final err = _errorFromEvent(event);
            completer.completeError(err);
          });

          worker.onMessage.listen((e) {
            final data = e.data;
            final res = WorkerResponseExt.from(data);
            if (!res.unwrapInPlace(ExceptionManager(), null)) return;
            if (res.error != null) {
              completer.completeError(res.error!);
            } else {
              completer.complete('processed message with result ${res.result}');
            }
          });

          var success = false;
          try {
            worker.postMessage('Hello');
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
            Url.revokeObjectUrl(ep.url);
          }
          worker.terminate();
        }
      });
    });
  });
}
