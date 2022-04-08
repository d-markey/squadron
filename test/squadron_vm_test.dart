@TestOn('vm')

import 'dart:io';

import 'package:squadron/squadron.dart';
import 'package:test/test.dart';

import 'classes/memory_logger.dart';
import 'test_suites/cancellation_test_suite.dart';
import 'test_suites/issues_test_suite.dart';
import 'test_suites/local_worker_test_suite.dart';
import 'test_suites/logger_test_suite.dart';
import 'test_suites/worker_pool_test_suite.dart';
import 'test_suites/worker_test_suite.dart';

void main() {
  group('NATIVE -', () {
    print('Running vm tests on ${Platform.operatingSystemVersion}...');

    final memoryLogger = MemoryLogger();

    setUp(() {
      Squadron.setId('workerTests');
      Squadron.logLevel = SquadronLogLevel.fine;
      Squadron.logger = memoryLogger;
      memoryLogger.clear();
    });

    group('Logger -', () {
      final currentLogger = Squadron.logger;
      final currentLogLevel = Squadron.logLevel;
      try {
        loggerTests();
      } finally {
        Squadron.logger = currentLogger;
        Squadron.logLevel = currentLogLevel;
      }
    });

    group("Worker -", () {
      workerTests();
    });

    group("Local Worker -", () {
      localWorkerTests();
    });

    group("Worker pool -", () {
      poolTests();

      group("Cancellation -", () {
        cancellationTests();
      });
    });

    group("GitHub Issues -", () {
      githubIssuesTests();
    });
  });
}
