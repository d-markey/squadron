@TestOn('vm || browser')

import 'package:squadron/squadron.dart';
import 'package:test/test.dart';

import 'test_suites/cancelation_test_suite.dart' as cancelation_test;
import 'test_suites/issues_test_suite.dart' as issues_test;
import 'test_suites/local_worker_test_suite.dart' as local_worker_test;
import 'test_suites/logger_test_suite.dart' as logger_test;
import 'test_suites/marshaler_test_suite.dart' as marshaler_test;
import 'test_suites/squadron_singleton_test_suite.dart' as singleton_test;
import 'test_suites/worker_pool_test_suite.dart' as worker_pool_test;
import 'test_suites/worker_test_suite.dart' as worker_test;
import 'worker_services/_test_context.dart';

void main() async {
  await TestContext.init('');

  group(TestContext.platformName, () {
    singleton_test.main();
  });

  group(TestContext.platformName, () {
    setUpAll(() {
      Squadron.setId('workerTests');
      Squadron.setLogger(ConsoleSquadronLogger());
      Squadron.logLevel = SquadronLogLevel.off;
      Squadron.debugMode = false;
    });

    logger_test.main();
    worker_test.main();
    worker_pool_test.main();
    cancelation_test.main();
    local_worker_test.main();
    marshaler_test.main();
    issues_test.main();
  });
}
