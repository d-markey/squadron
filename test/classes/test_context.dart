import 'package:squadron/squadron.dart';
import 'package:squadron/src/typedefs.dart';
import 'package:test/test.dart';

import '_test_context_stub.dart'
    if (dart.library.io) '../workers/vm/_test_context.dart'
    if (dart.library.html) '../workers/js/_test_context.dart'
    if (dart.library.js_interop) '../workers/wasm/_test_context.dart'
    as test_context;
import 'test_entry_points.dart';
import 'test_platform.dart';

class TestContext {
  TestContext._(this.workerPlatform);

  static Future<TestContext> init(String root,
      [TestPlatform? workerPlatform]) async {
    workerPlatform ??= test_context.platform;
    final testContext = TestContext._(workerPlatform);
    await testContext.entryPoints.set(root, workerPlatform);
    return testContext;
  }

  void run(void Function() testSuite) {
    group(
      '${workerPlatform.label} workers / ${clientPlatform.label} test client',
      testSuite,
    );
  }

  final TestPlatform workerPlatform;

  TestPlatform get clientPlatform => test_context.platform;
  String get clientPlatformName => test_context.platformName;

  final entryPoints = TestEntryPoints();

  Iterable<EntryPoint> get definedEntryPoints => entryPoints.defined;
}
