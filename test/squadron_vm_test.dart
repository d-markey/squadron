@TestOn('vm')

import 'dart:io';

import 'package:test/test.dart';

import 'squadron_worker_pool_test_suite.dart';
import 'squadron_worker_test_suite.dart';

void main() {
  print('Running vm tests on ${Platform.operatingSystemVersion}...');

  group("Worker", () {
    workerTests();
  });

  group("Worker pool", () {
    poolTests();
  });
}
