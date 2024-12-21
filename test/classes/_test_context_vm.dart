import 'dart:io';

import 'package:squadron/squadron.dart';

import '../workers/vm/cache_worker.dart' as entrypoint_cache;
import '../workers/vm/error_worker.dart' as entrypoint_error;
import '../workers/vm/installable_worker.dart' as entrypoint_installable;
import '../workers/vm/issues_worker.dart' as entrypoint_issues;
import '../workers/vm/local_client_worker.dart' as entrypoint_local_client;
import '../workers/vm/log_worker.dart' as entrypoint_log;
import '../workers/vm/not_a_worker.dart' as entrypoint_not_a_worker;
import '../workers/vm/prime_worker.dart' as entrypoint_prime;
import '../workers/vm/streaming_worker.dart' as entrypoint_streaming;
import '../workers/vm/test_worker.dart' as entrypoint_test;
import 'test_entry_points.dart';

const platform = SquadronPlatformType.vm;
String platformName = Platform.operatingSystemVersion;

const hasImageCodecs = false;

const hasChromiumBreakIterators = false;

const supportsWasmGc = false;

const isCrossOriginIsolated = false;

extension TestEntryPointsExt on TestEntryPoints {
  Future<void> set(String? root, SquadronPlatformType platform) async {
    if (platform != SquadronPlatformType.vm) {
      throw UnsupportedError('Unsupported platform $platform');
    }

    notAWorker = entrypoint_not_a_worker.start;

    cache = entrypoint_cache.start;
    installable = entrypoint_installable.start;
    issues = entrypoint_issues.start;
    local = entrypoint_local_client.start;
    prime = entrypoint_prime.start;

    log = entrypoint_log.start;
    streaming = entrypoint_streaming.start;
    test = entrypoint_test.start;
    errors = entrypoint_error.start;
    missingStartRequest = entrypoint_error.startWithMissingCommand;
  }
}
