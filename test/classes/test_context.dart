import 'package:squadron/squadron.dart';
import 'package:squadron/src/typedefs.dart';
import 'package:test/test.dart';

import '_test_context_stub.dart'
    if (dart.library.io) '../sample_vm_workers/_test_context.dart'
    if (dart.library.html) '../sample_js_workers/_test_context.dart'
    if (dart.library.js_interop) '../sample_wasm_workers/_test_context.dart'
    as platform_test_context;
import 'test_entry_points.dart';
import 'test_platform.dart';

final importedPlatform = platform_test_context.platform;
final importedPlatformName = platform_test_context.platformName;

class TestContext {
  TestContext._(this.platform, this.platformName);

  static Future<TestContext> init(String root,
      [TestPlatform? platform, String? platformName]) async {
    platform ??= importedPlatform;
    platformName ??= importedPlatformName;
    final testContext = TestContext._(platform, platformName);
    await platform_test_context.setEntryPoints(
      root,
      platform,
      testContext.entryPoints,
    );
    return testContext;
  }

  void run(void Function() testSuite) {
    group(platformName, testSuite);
  }

  final TestPlatform platform;
  final String platformName;

  final entryPoints = TestEntryPoints();

  bool get isVm => platform == TestPlatform.vm;
  bool get isJs => platform == TestPlatform.js;
  bool get isWasm => platform == TestPlatform.wasm;

  Iterable<EntryPoint> get definedEntryPoints => entryPoints.defined;
}
