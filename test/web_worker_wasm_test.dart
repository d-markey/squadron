@TestOn('browser && dart2wasm')
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:test/test.dart';
import 'package:web/web.dart' as web;

import 'classes/test_context.dart';

void main() async {
  final testContext = await TestContext.init('');
  execute(testContext);
}

void execute(TestContext testContext) => testContext.run(() {
      group("- WebWorker (${testContext.platform})", () {
        test('- classic Web worker', () async {
          final worker = web.Worker(testContext.entryPoints.echo!);
          expect(worker, isNotNull);
          final ready = Completer<void>();
          final completer = Completer<String>();
          worker.onerror = (JSAny? error) {
            if (!ready.isCompleted) ready.complete();
            web.console.log('RECEIVED ERROR $error'.jsify());
            completer.complete(error.dartify().toString());
          }.toJS;
          worker.onmessageerror = (JSAny? error) {
            if (!ready.isCompleted) ready.complete();
            web.console.log('RECEIVED MESSAGE ERROR $error'.jsify());
            completer.complete(error.dartify().toString());
          }.toJS;
          worker.onmessage = (web.MessageEvent? e) {
            if (!ready.isCompleted) {
              ready.complete();
              return;
            }
            web.console.log('RECEIVED MESSAGE ${e?.data}'.jsify());
            try {
              completer.complete(e?.data.dartify().toString());
            } catch (error) {
              completer.complete(error.toString());
            }
          }.toJS;
          await ready.future;
          worker.postMessage('Hello'.jsify());
          final res = await completer.future;
          expect(res, equals('ECHO "Hello"'));
          worker.terminate();
        });

        test('- native Web worker', () async {
          final worker = web.Worker(testContext.entryPoints.native!);
          expect(worker, isNotNull);
          final completer = Completer<String>();
          worker.onerror = (JSAny? error) {
            completer.complete(error.dartify().toString());
          }.toJS;
          worker.onmessage = (web.MessageEvent e) {
            try {
              completer.complete(e.data?.dartify().toString());
            } catch (error) {
              completer.complete(error.toString());
            }
          }.toJS;
          worker.postMessage('Hello'.jsify());
          var res = await completer.future;
          expect(res, equals('ECHO "Hello"'));
          worker.terminate();
        });

        test('- in-memory Web worker', () async {
          final worker = web.Worker(testContext.entryPoints.inMemory!);
          expect(worker, isNotNull);
          final completer = Completer<String>();
          worker.onerror = (JSAny? error) {
            completer.complete(error.dartify().toString());
          }.toJS;
          worker.onmessage = (web.MessageEvent e) {
            try {
              completer.complete(e.data?.dartify().toString());
            } catch (error) {
              completer.complete(error.toString());
            }
          }.toJS;
          worker.postMessage('Hello'.jsify());
          var res = await completer.future;
          expect(res, equals('ECHO "Hello"'));
          worker.terminate();
        });

        test('- missing Web worker', () async {
          final worker = web.Worker('not_found.js');
          expect(worker, isNotNull);
          final completer = Completer<String>();
          worker.onerror = (web.ErrorEvent? error) {
            if (error is web.ErrorEvent) {
              completer.complete('WORKER ERROR: ${error.message}');
            } else {
              completer.complete('WORKER ERROR: $error');
            }
          }.toJS;
          worker.onmessageerror = (web.ErrorEvent? error) {
            if (error is web.ErrorEvent) {
              completer.complete('WORKER MESSAGE ERROR: ${error.message}');
            } else {
              completer.complete('WORKER MESSAGE ERROR: $error');
            }
          }.toJS;
          worker.onmessage = (web.MessageEvent e) {
            try {
              completer.complete(e.data?.dartify().toString());
            } catch (error) {
              completer.complete('ERROR: $error');
            }
          }.toJS;
          worker.postMessage('Hello'.jsify());
          var res = await completer.future;
          expect(res, contains('WORKER ERROR'));
          worker.terminate();
        });
      });
    });
