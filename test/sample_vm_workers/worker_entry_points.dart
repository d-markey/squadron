import '../worker_services/worker_entry_points.dart' show EntryPoints;

import 'cache_worker.dart' as cache;
import 'installable_worker.dart' as installable;
import 'issues_worker.dart' as issues;
import 'local_client_worker.dart' as local_client;
import 'prime_worker.dart' as prime;
import 'test_worker.dart' as test;

const platform = 'NATIVE';

void setEntryPoints() {
  EntryPoints.cache = cache.start;
  EntryPoints.installable = installable.start;
  EntryPoints.issues = issues.start;
  EntryPoints.local = local_client.start;
  EntryPoints.prime = prime.start;

  EntryPoints.test = test.start;
  EntryPoints.failedInit = test.startWithException;
  EntryPoints.missingStartRequest = test.startWithMissingCommand;
  EntryPoints.invalidCommand = test.startWithInvalidCommand;
}
