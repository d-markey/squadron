import 'dart:io';

import '../../classes/test_entry_points.dart';
import '../../classes/test_platform.dart';
import 'cache_worker.dart' as entrypoint_cache;
import 'installable_worker.dart' as entrypoint_installable;
import 'issues_worker.dart' as entrypoint_issues;
import 'local_client_worker.dart' as entrypoint_local_client;
import 'not_a_worker.dart' as entrypoint_not_a_worker;
import 'prime_worker.dart' as entrypoint_prime;
import 'test_worker.dart' as entrypoint_test;

const platform = TestPlatform.vm;
String platformName = Platform.operatingSystemVersion;

extension TestEntryPointsExt on TestEntryPoints {
  Future<void> set(String root, TestPlatform platform) async {
    if (platform != TestPlatform.vm) {
      throw UnsupportedError('Unsupported platform $platform');
    }

    notAWorker = entrypoint_not_a_worker.start;

    cache = entrypoint_cache.start;
    installable = entrypoint_installable.start;
    issues = entrypoint_issues.start;
    local = entrypoint_local_client.start;
    prime = entrypoint_prime.start;

    test = entrypoint_test.start;
    missingStartRequest = entrypoint_test.startWithMissingCommand;
  }
}
