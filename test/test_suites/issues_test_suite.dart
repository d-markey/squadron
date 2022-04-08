import 'dart:async';

import 'package:squadron/squadron_service.dart';
import 'package:test/test.dart';

import '../worker_services/issues_service_worker.dart';

void githubIssuesTests() {
  setUp(() {});

  group('#8 - Exceptions from Streams must come through onError', () {
    test('Worker', () async {
      final worker = IssuesWorker();

      final stream = worker.issue_8([0, 1, 2, 3, 4]);

      final completer = Completer();
      final results = [];
      final errors = [];
      stream.listen((value) {
        results.add(value);
      }, onError: (err) {
        errors.add(err);
      }, onDone: () {
        completer.complete();
      });

      await completer.future;

      expect(results, equals([0, 1]));
      expect(errors.length, equals(1));
      expect(errors[0], isA<WorkerException>());
      expect((errors[0] as WorkerException).message,
          equals('issue 8 error message'));
    });

    test('Worker Pool', () async {
      final pool = IssuesWorkerPool();

      final stream = pool.issue_8([0, 1, 2, 3, 4]);

      final completer = Completer();
      final results = [];
      final errors = [];
      stream.listen((value) {
        results.add(value);
      }, onError: (err) {
        errors.add(err);
      }, onDone: () {
        completer.complete();
      });

      await completer.future;

      expect(results, equals([0, 1]));
      expect(errors.length, equals(1));
      expect(errors[0], isA<WorkerException>());
      expect((errors[0] as WorkerException).message,
          equals('issue 8 error message'));
    });
  });
}
