@TestOn('vm')

import 'dart:io';

import 'package:test/test.dart';

import 'worker_pool_test_suite.dart';
import 'worker_test_suite.dart';

void main() {
  print('Running vm tests on ${Platform.operatingSystemVersion}...');

  group("Worker - ", () {
    workerTests();
  });

  group("Worker pool - ", () {
    poolTests();
  });
}
