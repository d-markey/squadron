// ignore_for_file: file_names

import 'dart:async';

import 'package:squadron/squadron.dart';
import 'package:test/test.dart';
import 'package:using/using.dart';

import 'src/test_context.dart';
import 'src/utils.dart';
import 'worker_services/issues_service_worker.dart';

Future<void> main() => TestContext.run(execute);

const testScript = '11_issues_test.dart';

void execute(TestContext? tc) {
  if (tc == null) return;

  tc.launch(() {
    tc.group('- GITHUB ISSUES', () {
      tc.group('- #8 - Exceptions from Streams must come through onError', () {
        tc.test('- Using a Squadron worker', () async {
          await IssuesWorker(tc).useAsync((w) async {
            await w.start();
            final completer = Completer(), results = [], errors = [];
            w.issue_8([0, 1, 2, 3, 4]).listen(
              results.add,
              onError: errors.add,
              onDone: completer.complete,
              cancelOnError: false,
            );

            await completer.future;

            expect(results, [
              {'id': 1, 'num': 0},
              {'id': 2, 'num': 1}
            ]);
            expect(errors, hasLength(1));
            expect(errors.first, isA<WorkerException>());
            expect(errors.first, reports('issue 8 error message'));
          });
        });

        tc.test('- Using a worker pool', () async {
          await IssuesWorkerPool(tc).useAsync((p) async {
            await p.start();
            final completer = Completer(), results = [], errors = [];
            p.issue_8([0, 1, 2, 3, 4]).listen(
              results.add,
              onError: errors.add,
              onDone: completer.complete,
            );

            await completer.future;

            expect(results, [
              {'id': 1, 'num': 0},
              {'id': 2, 'num': 1}
            ]);
            expect(errors, hasLength((1)));
            expect(errors.first, isA<WorkerException>());
            expect(errors.first, reports('issue 8 error message'));
          });
        });
      });

      tc.group(
          '- #23 - Handle case where Map<int, _> is received as Map<JSString, _> in wasm worker',
          () {
        tc.test('- Using a Squadron worker', () async {
          await IssuesWorker(tc).useAsync((w) async {
            await w.issue_23([0], columnWidths: const {1: 125});
            await w.issue_23([0], columnWidths: const {2: 125});
            await w.issue_23([0], columnWidths: {-12: 125});
          });
        });

        tc.test('- Using a worker pool', () async {
          await IssuesWorkerPool(tc).useAsync((w) async {
            await Future.wait([
              w.issue_23([0], columnWidths: const {1: 125}),
              w.issue_23([0], columnWidths: const {2: 125}),
              w.issue_23([0], columnWidths: {-12: 125})
            ]);
          });
        });
      });

      tc.group('- #70 - ForwardStreamController leak', () {
        tc.test('- sendRequest should clean up active connections', () async {
          await IssuesWorker(tc).useAsync((w) async {
            await w.start();

            final initialCount = w.getStats().activeConnections;
            expect(initialCount, isZero);

            // Make multiple sendRequest calls
            for (int i = 0; i < 10; i++) {
              await w.getVersion();
            }

            // Give time for any async cleanup
            await Future.delayed(Duration(milliseconds: 100));

            // Verify controllers were cleaned up
            final finalCount = w.getStats().activeConnections;
            expect(finalCount, equals(initialCount),
                reason:
                    'Memory leak detected: ${finalCount - initialCount} connections retained after 10 requests');
          });
        });

        tc.test('- sendStreamingRequest should clean up active connections',
            () async {
          await IssuesWorker(tc).useAsync((w) async {
            await w.start();

            final initialCount = w.getStats().activeConnections;
            expect(initialCount, isZero);

            // Make a streaming request and fully consume it
            final values = <dynamic>[];
            await for (final value in w.issue_8([0, 1])) {
              values.add(value);
            }

            // Give time for cleanup
            await Future.delayed(Duration(milliseconds: 100));

            final finalCount = w.getStats().activeConnections;
            expect(finalCount, equals(initialCount),
                reason:
                    'Memory leak detected: ${finalCount - initialCount} connections retained after streaming request');
          });
        });

        tc.test('- Early canceled streams should clean up active connections',
            () async {
          await IssuesWorker(tc).useAsync((w) async {
            await w.start();

            final initialCount = w.getStats().activeConnections;
            expect(initialCount, isZero);

            // Create a streaming request but cancel it early by only taking first value
            final firstValue = await w.issue_8([0, 1, 2, 3, 4]).first;
            expect(firstValue, {'id': 1, 'num': 0});

            // Give time for cleanup after early cancellation
            await Future.delayed(Duration(milliseconds: 200));

            final finalCount = w.getStats().activeConnections;
            expect(finalCount, equals(initialCount),
                reason:
                    'Memory leak detected: ${finalCount - initialCount} connections retained after early stream cancellation');
          });
        });
      });
    });
  });
}
