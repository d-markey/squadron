@TestOn('vm || browser')
library;

import 'dart:async';

import 'package:squadron/squadron.dart';
import 'package:test/test.dart';
import 'package:using/using.dart';

import 'classes/test_context.dart';
import 'classes/utils.dart';
import 'worker_services/issues_service_worker.dart';

void main() async {
  final testContext = await TestContext.init('');
  execute(testContext);
}

String testScript = 'issues_test.dart';

void execute(TestContext tc) {
  tc.run(() {
    tc.group("- GitHub Issues", () {
      tc.group('- #8 - Exceptions from Streams must come through onError', () {
        tc.test('- Squadron Worker', () async {
          await IssuesWorker(
            tc,
          ).useAsync((worker) async {
            await worker.start();

            final stream = worker.issue_8([0, 1, 2, 3, 4]);

            final completer = Completer();
            final results = [], errors = [];
            stream.listen(
              results.add,
              onError: errors.add,
              onDone: completer.complete,
            );

            await completer.future;

            expect(results, equals([0, 1]));
            expect(errors.length, equals(1));
            expect(errors[0], isA<WorkerException>());
            lowerCaseCheck((errors[0] as WorkerException).message,
                equals('issue 8 error message'));
          });
        });

        tc.test('- Worker Pool', () async {
          await IssuesWorkerPool(
            tc,
          ).useAsync((pool) async {
            await pool.start();

            final stream = pool.issue_8([0, 1, 2, 3, 4]);

            final completer = Completer();
            final results = [], errors = [];
            stream.listen(
              results.add,
              onError: errors.add,
              onDone: completer.complete,
            );

            await completer.future;

            expect(results, equals([0, 1]));
            expect(errors.length, equals(1));
            expect(errors[0], isA<WorkerException>());
            lowerCaseCheck((errors[0] as WorkerException).message,
                equals('issue 8 error message'));
          });
        });
      });
    });
  });
}
