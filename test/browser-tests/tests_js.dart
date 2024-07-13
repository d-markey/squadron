// this test suite will execute Squadron using "html" + "js" libraries

import 'dart:html';

import '../cancelation_test.dart' as cancelation_test;
import '../issues_test.dart' as issues_test;
import '../local_worker_test.dart' as local_worker_test;
import '../logging_test.dart' as logging_test;
import '../marshaler_test.dart' as marshaler_test;
import '../shared_channel_test.dart' as shared_channel_test;
import '../web_worker_js_test.dart' as web_worker_test;
import '../worker_pool_test.dart' as worker_pool_test;
import '../worker_test.dart' as worker_test;

final executors = {
  'Classic Web Workers': (
    script: web_worker_test.testScript,
    runner: web_worker_test.execute
  ),
  'Squadron Workers': (
    script: worker_test.testScript,
    runner: worker_test.execute
  ),
  'Squadron Worker Pools': (
    script: worker_pool_test.testScript,
    runner: worker_pool_test.execute
  ),
  'Shared Channel': (
    script: shared_channel_test.testScript,
    runner: shared_channel_test.execute
  ),
  'Local Workers': (
    script: local_worker_test.testScript,
    runner: local_worker_test.execute
  ),
  'Logging': (script: logging_test.testScript, runner: logging_test.execute),
  'Marshalers': (
    script: marshaler_test.testScript,
    runner: marshaler_test.execute
  ),
  'Cancelation Tokens': (
    script: cancelation_test.testScript,
    runner: cancelation_test.execute
  ),
  'GitHub Issues': (
    script: issues_test.testScript,
    runner: issues_test.execute
  ),
};

void reportStatus(String status) =>
    window.parent?.postMessage(status, window.location.origin);
