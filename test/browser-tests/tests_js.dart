// this test suite will execute Squadron using "html" + "js" libraries

import 'dart:html';

import '../00_not_a_worker_test.dart' as not_a_worker_test;
import '../01_web_worker_js_test.dart' as web_worker_test;
import '../02_logging_test.dart' as logging_test;
import '../03_worker_test.dart' as worker_test;
import '../04_worker_streaming_test.dart' as streaming_test;
import '../05_local_worker_test.dart' as local_worker_test;
import '../06_shared_channel_test.dart' as shared_channel_test;
import '../07_cancelation_test.dart' as cancelation_test;
import '../08_marshaler_test.dart' as marshaler_test;
import '../09_worker_pool_test.dart' as worker_pool_test;
import '../10_issues_test.dart' as issues_test;

final executors = {
  'Classic Web Workers': (
    script: web_worker_test.testScript,
    runner: web_worker_test.execute,
  ),
  'Squadron Workers': (
    script: worker_test.testScript,
    runner: worker_test.execute,
  ),
  'Streaming': (
    script: streaming_test.testScript,
    runner: streaming_test.execute,
  ),
  'Squadron Worker Pools': (
    script: worker_pool_test.testScript,
    runner: worker_pool_test.execute,
  ),
  'Shared Channel': (
    script: shared_channel_test.testScript,
    runner: shared_channel_test.execute
  ),
  'Local Workers': (
    script: local_worker_test.testScript,
    runner: local_worker_test.execute,
  ),
  'Logging': (
    script: logging_test.testScript,
    runner: logging_test.execute,
  ),
  'Marshalers': (
    script: marshaler_test.testScript,
    runner: marshaler_test.execute,
  ),
  'Cancelation Tokens': (
    script: cancelation_test.testScript,
    runner: cancelation_test.execute,
  ),
  'GitHub Issues': (
    script: issues_test.testScript,
    runner: issues_test.execute,
  ),
  'Not a worker': (
    script: not_a_worker_test.testScript,
    runner: not_a_worker_test.execute,
  ),
};

void reportStatus(String status) =>
    window.parent?.postMessage(status, window.location.origin);
