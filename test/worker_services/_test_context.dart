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
  static Future<void> init(String root) async {
    await platform_test_context.setEntryPoints(root);
    _platform = platform_test_context.platform;
    _platformName = platform_test_context.platformName;
  }

  static TestPlatform _platform = TestPlatform.unknown;
  static TestPlatform get platform => _platform;

  static bool get isVm => _platform == TestPlatform.vm;
  static bool get isJs => _platform == TestPlatform.js;
  static bool get isWasm => _platform == TestPlatform.wasm;

  static String _platformName = 'N/A';
  static String get platformName => _platformName;

  static Iterable<EntryPoint> get definedEntryPoints => [
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

  static final entryPoints = EntryPoints();
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
