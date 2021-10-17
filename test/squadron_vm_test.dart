@TestOn('vm')

import 'dart:io';
import 'package:test/test.dart';

import 'squadron_vm_worker_pool_test.dart';
import 'squadron_vm_worker_test.dart';

void main() {
  print('Running tests on ${Platform.operatingSystem}...');

  group("Worker", () {
    workerTests();
  });

  group("Worker pool", () {
    poolTests();
  });
}
