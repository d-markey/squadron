@TestOn('browser')

import 'dart:async';
import 'dart:html' as web;

import 'package:test/test.dart';

import 'classes/test_context.dart';

void main() async {
  final testContext = await TestContext.init('');
  execute(testContext);
}

void execute(TestContext testContext) => testContext.run(() {
      group("- WebWorker", () {
        test('- classic Web worker', () async {
          final worker = web.Worker(testContext.entryPoints.echo!);
          expect(worker, isNotNull);
          final completer = Completer<String>();
          worker.onError.listen((error) {
            completer.complete(error.toString());
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

        test('- native Web worker', () async {
          final worker = web.Worker(testContext.entryPoints.native!);
          expect(worker, isNotNull);
          final completer = Completer<String>();
          worker.onError.listen((error) {
            completer.complete(error.toString());
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

        test('- in-memory Web worker', () async {
          final worker = web.Worker(testContext.entryPoints.inMemory!);
          expect(worker, isNotNull);
          final completer = Completer<String>();
          worker.onError.listen((error) {
            completer.complete(error.toString());
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

        test('- missing Web worker', () async {
          final worker = web.Worker('not_found.js');
          expect(worker, isNotNull);
          final completer = Completer<String>();
          worker.onError.listen((error) {
            if (error is web.ErrorEvent) {
              completer.complete('WORKER ERROR: ${error.message}');
            } else {
              completer.complete('WORKER ERROR: $error');
            }
          });
          worker.onMessage.listen((web.MessageEvent e) {
            try {
              completer.complete(e.data);
            } catch (error) {
              completer.complete('ERROR: $error');
            }
          });
          worker.postMessage('Hello');
          var res = await completer.future;
          expect(res, contains('WORKER ERROR'));
          worker.terminate();
        });
      });
    });
