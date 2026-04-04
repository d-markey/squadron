@TestOn('vm')
library;

import 'package:test/test.dart';

import 'src/test_context.dart';

import '01_not_a_worker_suite.dart' as not_a_worker;
import '02_logging_suite.dart' as logging;
import '03_converter_suite.dart' as converter;
import '04_worker_suite.dart' as worker;
import '05_worker_errors_suite.dart' as worker_errors;
import '06_worker_streaming_suite.dart' as streaming;
import '07_local_worker_suite.dart' as local_worker;
import '08_shared_channel_suite.dart' as shared_channel;
import '09_cancelation_suite.dart' as cancelation;
import '10_marshaler_suite.dart' as marshalers;
import '11_worker_pool_suite.dart' as worker_pool;
import '12_issues_suite.dart' as issues;

Future<void> main() => TestContext.run(execute);

void execute(TestContext? tc) {
  not_a_worker.execute(tc);
  logging.execute(tc);
  converter.execute(tc);
  worker.execute(tc);
  worker_errors.execute(tc);
  streaming.execute(tc);
  local_worker.execute(tc);
  shared_channel.execute(tc);
  cancelation.execute(tc);
  marshalers.execute(tc);
  worker_pool.execute(tc);
  issues.execute(tc);
}
