import 'dart:io';

import 'package:squadron/squadron.dart';

import '../workers/vm/cache_worker.dart' as entrypoint_cache;
import '../workers/vm/error_worker.dart' as entrypoint_error;
import '../workers/vm/installable_worker.dart' as entrypoint_installable;
import '../workers/vm/issues_worker.dart' as entrypoint_issues;
import '../workers/vm/local_client_worker.dart' as entrypoint_local_client;
import '../workers/vm/log_worker.dart' as entrypoint_log;
import '../workers/vm/not_a_worker.dart' as entrypoint_not_a_worker;
import '../workers/vm/person_worker.dart' as entrypoint_person;
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

    notAWorker = entrypoint_not_a_worker.entryPoint;

    cache = entrypoint_cache.entryPoint;
    installable = entrypoint_installable.entryPoint;
    issues = entrypoint_issues.entryPoint;
    local = entrypoint_local_client.entryPoint;
    prime = entrypoint_prime.entryPoint;

    log = entrypoint_log.entryPoint;
    streaming = entrypoint_streaming.entryPoint;
    test = entrypoint_test.entryPoint;
    person = entrypoint_person.entryPoint;
    errors = entrypoint_error.entryPoint;
    missingStartRequest = entrypoint_error.entryPointWithMissingCommand;
  }
}
