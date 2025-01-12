import 'dart:async';

import 'package:squadron/squadron.dart';
import 'package:squadron/version.dart' as sq;

import '../worker_services/cache_service_worker.dart';
import '../worker_services/error_service_worker.dart';
import '../worker_services/installable_service_worker.dart';
import '../worker_services/issues_service_worker.dart';
import '../worker_services/local_client_worker.dart';
import '../worker_services/local_workers/local_service.dart';
import '../worker_services/log_service_worker.dart';
import '../worker_services/prime_service_worker.dart';
import '../worker_services/squadron_version.dart';
import '../worker_services/streaming_service_worker.dart';
import '../worker_services/test_service_worker.dart';
import 'console_to_html.dart';
import 'test_context.dart';
import 'test_suites.dart';

Future<TestContext?> init({SquadronPlatformType? workerPlatform}) async {
  final context = await TestContext.init(
    RunMode.launch,
    '~/..',
    workerPlatform ?? Squadron.platformType,
  );

  if (context == null) {
    Log.writeln('Failed to initialize a test context', [Log.red]);
    return null;
  }

  await displayVersions(context);

  return context;
}

Future<Iterable<({String label, int tests})>> discover() async {
  final context = await TestContext.init(
    RunMode.discover,
    '~/..',
    Squadron.platformType,
  );

  if (context == null) {
    Log.writeln('Failed to initialize a test context', [Log.red]);
    return const [];
  }

  for (var testSuite in testSuites) {
    context.discover(testSuite.runner);
  }
  await context.wait();

  return context.rootGroups;
}

Future<void> _displayVersion(
    EntryPoint? entryPoint, WorkerVersion Function() workerBuilder) async {
  if (entryPoint == null) return;
  WorkerVersion? worker;
  try {
    worker = workerBuilder();
    final version = await worker.getVersion();
    final color = (version == sq.version) ? Log.green : Log.red;
    Log.writeln('Worker $entryPoint: compiled with Squadron $version', [color]);
  } catch (ex) {
    Log.writeln('Failed to get version for $entryPoint: $ex', [Log.red]);
  } finally {
    worker?.terminate();
  }
}

Future<void> displayVersions([TestContext? context]) async {
  final ctx = context ??
      await TestContext.init(
        RunMode.discover,
        '~/..',
        Squadron.platformType,
      );

  if (ctx == null) {
    Log.writeln('Failed to initialize a test context', [Log.red]);
    return;
  }

  await Future.wait([
    _displayVersion(
      ctx.entryPoints.cache,
      () => CacheWorker(ctx),
    ),
    _displayVersion(
      ctx.entryPoints.installable,
      () => InstallableWorker(ctx),
    ),
    _displayVersion(
      ctx.entryPoints.issues,
      () => IssuesWorker(ctx),
    ),
    _displayVersion(
      ctx.entryPoints.local,
      () => LocalClientWorker(ctx, LocalWorker.create(LocalServiceImpl())),
    ),
    _displayVersion(
      ctx.entryPoints.prime,
      () => PrimeWorker(ctx, null),
    ),
    _displayVersion(
      ctx.entryPoints.log,
      () => LogWorker(ctx),
    ),
    _displayVersion(
      ctx.entryPoints.streaming,
      () => StreamingServiceWorker(ctx),
    ),
    _displayVersion(
      ctx.entryPoints.test,
      () => TestWorker(ctx),
    ),
    _displayVersion(
      ctx.entryPoints.errors,
      () => ErrorWorker(ctx),
    )
  ]);
}

void launch(TestContext context, Iterable<String> testLabels) {
  if (testLabels.isEmpty) return;

  for (var testLabel in testLabels) {
    context.onlyTests.add(
      RegExp('^${RegExp.escape(testLabel)}.*', caseSensitive: false),
    );
  }

  Log.writeln(
      'Selected tests: ${testLabels.map((t) => t.startsWith('- ') ? t.substring(2) : t).join(', ')}',
      [Log.bold]);
  Log.writeln('Test Runner running on ${context.runnerPlatformName}');
  Log.writeln('Workers running on ${context.workerPlatformName}');

  for (var testSuite in testSuites) {
    testSuite.runner(context);
  }
}
