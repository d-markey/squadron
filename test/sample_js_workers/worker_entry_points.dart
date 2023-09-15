import '../worker_services/worker_entry_points.dart' show EntryPoints;

const platform = 'WEB';

void setEntryPoints() {
  EntryPoints.echo = 'sample_js_workers/echo_worker.dart.js';

  EntryPoints.cache = 'sample_js_workers/cache_worker.dart.js';
  EntryPoints.installable = 'sample_js_workers/installable_worker.dart.js';
  EntryPoints.issues = 'sample_js_workers/issues_worker.dart.js';
  EntryPoints.local = 'sample_js_workers/local_client_worker.dart.js';
  EntryPoints.prime = 'sample_js_workers/prime_worker.dart.js';

  EntryPoints.test = 'sample_js_workers/test_worker.dart.js';
  EntryPoints.failedInit = 'sample_js_workers/test_worker_failing.dart.js';
  EntryPoints.invalidCommand = 'sample_js_workers/test_worker_invalid.dart.js';
}
