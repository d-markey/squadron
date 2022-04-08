import '../worker_services/worker_entry_points.dart' show EntryPoints;

void setEntryPoints() {
  EntryPoints.bitcoin = 'sample_js_workers/bitcoin_worker.dart.js';
  EntryPoints.cache = 'sample_js_workers/cache_worker.dart.js';
  EntryPoints.echo = 'sample_js_workers/echo_worker.dart.js';
  EntryPoints.failing = 'sample_js_workers/failing_worker.dart.js';
  EntryPoints.invalid = 'sample_js_workers/invalid_worker.dart.js';
  EntryPoints.issues = 'sample_js_workers/issues_worker.dart.js';
  EntryPoints.local = 'sample_js_workers/local_client_worker.dart.js';
  EntryPoints.piDigits = 'sample_js_workers/pi_digits_worker.dart.js';
  EntryPoints.prime = 'sample_js_workers/prime_worker.dart.js';
  EntryPoints.rogue = 'sample_js_workers/rogue_worker.dart.js';
  EntryPoints.test = 'sample_js_workers/test_worker.dart.js';
}
