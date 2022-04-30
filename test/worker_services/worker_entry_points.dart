import '../sample_vm_workers/worker_entry_points.dart'
    if (dart.library.js) '../sample_js_workers/worker_entry_points.dart'
    if (dart.library.html) '../sample_js_workers/worker_entry_points.dart';

class EntryPoints {
  static void init() {
    setEntryPoints();
  }

  static Iterable<Object> get entryPoints => [
        echo,
        cache,
        issues,
        local,
        prime,
        test,
        failedInit,
        invalidCommand,
        missingStartRequest,
      ].where((e) => e != null).cast<Object>();

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
