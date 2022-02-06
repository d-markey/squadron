@TestOn('vm')

import 'dart:io';

import 'package:squadron/squadron.dart';
import 'package:test/test.dart';

import 'cancellation_test_suite.dart';
import 'logger_test_suite.dart';
import 'memory_logger.dart';
import 'worker_pool_test_suite.dart';
import 'worker_test_suite.dart';

void main() {
  group('NATIVE', () {
    print('Running vm tests on ${Platform.operatingSystemVersion}...');

    final memoryLogger = MemoryLogger();

    setUp(() {
      Squadron.setId('workerTests');
      Squadron.logLevel = SquadronLogLevel.FINE;
      Squadron.logger = memoryLogger;
      memoryLogger.clear();
    });

    group('Logger - ', () {
      final currentLogger = Squadron.logger;
      final currentLogLevel = Squadron.logLevel;
      try {
        loggerTests();
      } finally {
        Squadron.logger = currentLogger;
        Squadron.logLevel = currentLogLevel;
      }
    });

    group("Worker - ", () {
      workerTests();
    });

    group("Worker pool - ", () {
      poolTests();

      group("Cancellation - ", () {
        cancellationTests();
      });
    });
  });
}
