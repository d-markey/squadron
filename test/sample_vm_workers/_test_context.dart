import 'dart:io';

import '../classes/test_context.dart';
import 'cache_worker.dart' as cache;
import 'installable_worker.dart' as installable;
import 'issues_worker.dart' as issues;
import 'local_client_worker.dart' as local_client;
import 'prime_worker.dart' as prime;
import 'test_worker.dart' as test;

const platform = TestPlatform.vm;
String platformName = Platform.operatingSystemVersion;

extension EntryPointsExt on TestContext {
  Future<void> setEntryPoints(String root) {
    entryPoints.cache = cache.start;
    entryPoints.installable = installable.start;
    entryPoints.issues = issues.start;
    entryPoints.local = local_client.start;
    entryPoints.prime = prime.start;

    entryPoints.test = test.start;
    entryPoints.missingStartRequest = test.startWithMissingCommand;

    return Future.value();
  }
}
