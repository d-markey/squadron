@TestOn('vm')

import 'dart:io';

import 'package:squadron/squadron.dart';
import 'package:test/test.dart';

import 'test_suites/cancellation_test_suite.dart';
import 'test_suites/issues_test_suite.dart';
import 'test_suites/local_worker_test_suite.dart';
import 'test_suites/logger_test_suite.dart';
import 'test_suites/squadron_singleton_test_suite.dart';
import 'test_suites/worker_pool_test_suite.dart';
import 'test_suites/worker_test_suite.dart';
import 'worker_services/worker_entry_points.dart';

void main() {
  EntryPoints.init();

  group('NATIVE', () {
    print('Running vm tests on ${Platform.operatingSystemVersion}...');

    setUp(() {
      Squadron.setId('workerTests');
      Squadron.logLevel = SquadronLogLevel.off;
    });

    group('- Squadron Singleton', squadronSingletonTests);
    group('- Logging', loggerTests);
    group("- Worker", workerTests);
    group("- WorkerPool", poolTests);
    group("- Cancellation", cancellationTests);
    group("- LocalWorker", localWorkerTests);
    group("- GitHub Issues", githubIssuesTests);
  });
}
