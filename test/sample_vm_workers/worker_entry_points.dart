import '../worker_services/worker_entry_points.dart' show EntryPoints;

import 'bitcoin_worker.dart' as bitcoin_isolate;
import 'cache_worker.dart' as cache_isolate;
import 'failing_worker.dart' as failing_isolate;
import 'invalid_worker.dart' as invalid_isolate;
import 'issues_worker.dart' as issues_isolate;
import 'local_client_worker.dart' as local_client_isolate;
import 'pi_digits_worker.dart' as pi_digits_isolate;
import 'prime_worker.dart' as prime_isolate;
import 'rogue_worker.dart' as rogue_isolate;
import 'test_worker.dart' as test_isolate;

void setEntryPoints() {
  EntryPoints.bitcoin = bitcoin_isolate.start;
  EntryPoints.cache = cache_isolate.start;
  EntryPoints.failing = failing_isolate.start;
  EntryPoints.failingWithMissingCommand =
      failing_isolate.startWithMissingCommand;
  EntryPoints.invalid = invalid_isolate.start;
  EntryPoints.issues = issues_isolate.start;
  EntryPoints.local = local_client_isolate.start;
  EntryPoints.piDigits = pi_digits_isolate.start;
  EntryPoints.prime = prime_isolate.start;
  EntryPoints.rogue = rogue_isolate.start;
  EntryPoints.test = test_isolate.start;
}
