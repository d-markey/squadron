import '../00_jsify_dartify_test.dart' as jsify_dartify;
import '../00_not_a_worker_test.dart' as not_a_worker;
import '../01_web_worker_test.dart' as web_worker;
import '../02_logging_test.dart' as logging;
import '../03_converter_test.dart' as converter;
import '../04_worker_test.dart' as worker;
import '../05_worker_errors_test.dart' as worker_errors;
import '../06_worker_streaming_test.dart' as streaming;
import '../07_local_worker_test.dart' as local_worker;
import '../08_shared_channel_test.dart' as shared_channel;
import '../09_cancelation_test.dart' as cancelation;
import '../10_marshaler_test.dart' as marshalers;
import '../11_worker_pool_test.dart' as worker_pool;
import '../12_issues_test.dart' as issues;
import 'test_context.dart';

class TestSuite {
  const TestSuite(this.script, this.runner);

  final String script;
  final void Function(TestContext?) runner;
}

const testSuites = [
  TestSuite(not_a_worker.testScript, not_a_worker.execute),
  TestSuite(jsify_dartify.testScript, jsify_dartify.execute),
  TestSuite(web_worker.testScript, web_worker.execute),
  TestSuite(worker.testScript, worker.execute),
  TestSuite(worker_errors.testScript, worker_errors.execute),
  TestSuite(streaming.testScript, streaming.execute),
  TestSuite(worker_pool.testScript, worker_pool.execute),
  TestSuite(shared_channel.testScript, shared_channel.execute),
  TestSuite(local_worker.testScript, local_worker.execute),
  TestSuite(logging.testScript, logging.execute),
  TestSuite(converter.testScript, converter.execute),
  TestSuite(marshalers.testScript, marshalers.execute),
  TestSuite(cancelation.testScript, cancelation.execute),
  TestSuite(issues.testScript, issues.execute),
];
