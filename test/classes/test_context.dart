import 'package:squadron/squadron.dart';

import '../sample_vm_workers/_test_context.dart'
    if (dart.library.js) '../sample_js_workers/_test_context.dart'
    if (dart.library.html) '../sample_js_workers/_test_context.dart'
    as platform_test_context;

enum TestPlatform {
  unknown,
  vm,
  js,
  wasm,
}

class TestContext {
  TestContext._(this.platform, this.platformName);

  static Future<TestContext> init(String root) async {
    final testContext = TestContext._(
        platform_test_context.platform, platform_test_context.platformName);
    await testContext.setEntryPoints(root);
    return testContext;
  }

  void run(void Function() testSuite) {
    testSuite();
    // group(platformName, testSuite);
  }

  final TestPlatform platform;

  bool get isVm => platform == TestPlatform.vm;
  bool get isJs => platform == TestPlatform.js;
  bool get isWasm => platform == TestPlatform.wasm;

  final String platformName;

  Iterable<EntryPoint> get definedEntryPoints => [
        entryPoints.echo,
        entryPoints.native,
        entryPoints.cache,
        entryPoints.installable,
        entryPoints.issues,
        entryPoints.local,
        entryPoints.prime,
        entryPoints.test,
        // entryPoints.failedInit,
        // entryPoints.invalidCommand,
        entryPoints.missingStartRequest,
      ].whereType<EntryPoint>();

  final entryPoints = EntryPoints();
}

class EntryPoints {
  dynamic echo;
  dynamic inMemory;
  dynamic native;

  dynamic cache;
  dynamic installable;
  dynamic issues;
  dynamic local;
  dynamic prime;

  dynamic test;
  dynamic failedInit;
  dynamic invalidCommand;
  dynamic missingStartRequest;
}
