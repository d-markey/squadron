import 'package:squadron/squadron.dart';

import '../sample_vm_workers/worker_entry_points.dart'
    if (dart.library.js) '../sample_js_workers/worker_entry_points.dart'
    if (dart.library.html) '../sample_js_workers/worker_entry_points.dart'
    as platform_entrypoints;

class EntryPoints {
  static void init() {
    _platform = platform_entrypoints.platform;
    platform_entrypoints.setEntryPoints();
  }

  static String _platform = 'N/A';

  static String get platform => _platform;

  static Iterable<EntryPoint> get entryPoints => [
        echo,
        cache,
        issues,
        local,
        prime,
        test,
        failedInit,
        invalidCommand,
        missingStartRequest,
      ].where((e) => e != null).cast<EntryPoint>();

  static dynamic echo;

  static dynamic cache;
  static dynamic issues;
  static dynamic local;
  static dynamic prime;

  static dynamic test;
  static dynamic failedInit;
  static dynamic invalidCommand;
  static dynamic missingStartRequest;
}
