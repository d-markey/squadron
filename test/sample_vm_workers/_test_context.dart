import 'dart:io';

import '../classes/test_entry_points.dart';
import '../classes/test_platform.dart';
import 'cache_worker.dart' as cache;
import 'installable_worker.dart' as installable;
import 'issues_worker.dart' as issues;
import 'local_client_worker.dart' as local_client;
import 'prime_worker.dart' as prime;
import 'test_worker.dart' as test;

const platform = TestPlatform.vm;
String platformName = Platform.operatingSystemVersion;

Future<void> setEntryPoints(
    String root, TestPlatform platform, TestEntryPoints entryPoints) async {
  print('Test context platform = $platform');

  if (platform != TestPlatform.vm) {
    throw UnsupportedError('Unsupported platform $platform');
  }

  entryPoints.cache = cache.start;
  entryPoints.installable = installable.start;
  entryPoints.issues = issues.start;
  entryPoints.local = local_client.start;
  entryPoints.prime = prime.start;

  entryPoints.test = test.start;
  entryPoints.missingStartRequest = test.startWithMissingCommand;
}
