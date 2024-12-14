// ignore_for_file: file_names

@TestOn('vm || browser')
library;

import 'dart:async';

import 'package:squadron/squadron.dart';
import 'package:test/test.dart';
import 'package:using/using.dart';

import 'classes/test_context.dart';
import 'classes/utils.dart';
import 'worker_services/issues_service_worker.dart';

Future<void> main() => TestContext.run(execute);

const testScript = '11_issues_test.dart';

void execute(TestContext? tc) {
  if (tc == null) return;

  tc.launch(() {
    tc.group("- GitHub Issues", () {
      tc.group('- #8 - Exceptions from Streams must come through onError', () {
        tc.test('- Squadron Worker', () async {
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

        tc.test('- Worker Pool', () async {
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
        tc.test('- Squadron Worker', () async {
          await IssuesWorker(tc).useAsync((w) async {
            await w.issue_23([0], columnWidths: const {1: 125});
            await w.issue_23([0], columnWidths: const {2: 125});
            await w.issue_23([0], columnWidths: {-12: 125});
          });
        });
      });
    });
  });
}
