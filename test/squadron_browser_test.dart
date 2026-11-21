@TestOn('dart2js || dart2wasm')
library;

import 'package:test/test.dart';

import '00_jsify_dartify_suite.dart' as jsify;
import '00_web_worker_suite.dart' as web_worker;
import '01_not_a_worker_suite.dart' as not_a_worker;
import '02_logging_suite.dart' as logging;
import '03_converter_suite.dart' as converter;
import '04_worker_suite.dart' as worker;
import '05_worker_errors_suite.dart' as worker_errors;
import '06_worker_streaming_suite.dart' as streaming;
import '07_local_worker_suite.dart' as local_worker;
import '08_channel_multiplexer_suite.dart' as multiplexer;
import '08_shared_channel_suite.dart' as shared_channel;
import '08_stream_transport_suite.dart' as process_transport;
import '09_cancelation_suite.dart' as cancelation;
import '10_marshaler_suite.dart' as marshalers;
import '11_worker_pool_suite.dart' as worker_pool;
import '12_issues_suite.dart' as issues;
import 'src/test_context.dart';

Future<void> main() => TestContext.run(execute);

void execute(TestContext tc) {
  jsify.execute(tc);
  not_a_worker.execute(tc);
  web_worker.execute(tc);
  logging.execute(tc);
  converter.execute(tc);
  worker.execute(tc);
  worker_errors.execute(tc);
  streaming.execute(tc);
  local_worker.execute(tc);
  multiplexer.execute(tc);
  process_transport.execute(tc);
  shared_channel.execute(tc);
  cancelation.execute(tc);
  marshalers.execute(tc);
  worker_pool.execute(tc);
  issues.execute(tc);
}
