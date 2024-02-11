import 'dart:io';

import '../worker_services/_test_context.dart' show TestPlatform, TestContext;
import 'cache_worker.dart' as cache;
import 'installable_worker.dart' as installable;
import 'issues_worker.dart' as issues;
import 'local_client_worker.dart' as local_client;
import 'prime_worker.dart' as prime;
import 'test_worker.dart' as test;

const platform = TestPlatform.vm;
String platformName = Platform.operatingSystemVersion;

Future<void> setEntryPoints(String root) {
  TestContext.entryPoints.cache = cache.start;
  TestContext.entryPoints.installable = installable.start;
  TestContext.entryPoints.issues = issues.start;
  TestContext.entryPoints.local = local_client.start;
  TestContext.entryPoints.prime = prime.start;

  TestContext.entryPoints.test = test.start;
  // TestContext.entryPoints.failedInit = test.startWithException;
  TestContext.entryPoints.missingStartRequest = test.startWithMissingCommand;
  // TestContext.entryPoints.invalidCommand = test.startWithInvalidCommand;

  return Future.value();
}
