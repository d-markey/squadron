@TestOn('browser')

// needs a separate file because web_worker_test_suite.dart imports 'dart:html'

import 'package:squadron/squadron.dart';
import 'package:test/test.dart';

import 'test_suites/web_worker_test_suite.dart' as web_worker_test;
import 'worker_services/_test_context.dart';

void main() async {
  await TestContext.init('');

  group(TestContext.platformName, () {
    setUp(() {
      Squadron.setId('workerTests');
      Squadron.setLogger(ConsoleSquadronLogger());
      Squadron.logLevel = SquadronLogLevel.off;
      Squadron.debugMode = false;
    });

    web_worker_test.main();
  });
}
