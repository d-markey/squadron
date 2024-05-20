import '../cancelation_test.dart' as cancelation_test;
import '../issues_test.dart' as issues_test;
import '../local_worker_test.dart' as local_worker_test;
import '../logging_test.dart' as logging_test;
import '../marshaler_test.dart' as marshaler_test;
import '../web_worker_test.dart' as web_worker_test;
import '../worker_pool_test.dart' as worker_pool_test;
import '../worker_test.dart' as worker_test;

final executors = {
  'Classic Web Workers': web_worker_test.execute,
  'Squadron Workers': worker_test.execute,
  'Squadron Worker Pools': worker_pool_test.execute,
  'Local Workers': local_worker_test.execute,
  'Logging': logging_test.execute,
  'Marshalers': marshaler_test.execute,
  'Cancelation Tokens': cancelation_test.execute,
  'GitHub Issues': issues_test.execute,
};

final executorLabels = executors.keys.toList();

String getTestId(String label) => '\$${label.replaceAll(' ', '-')}';
