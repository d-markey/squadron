import 'dart:async';

import 'expect.dart';
import 'logger.dart';
import '../test/worker_services/sample_service.dart';

final sampleWorkerTests = {
  'Sample Worker - start / stop': testSampleWorkerStartStop,
};

Future<bool> testSampleWorkerStartStop(Logger logger) async {
  try {
    final worker = SampleWorker('/sample_js_workers/sample_worker.dart.js');
    expect(worker.started == null, 'worker.started should be null');
    expect(worker.idleTime == Duration.zero, 'worker.idleTime should be zero');
    expect(worker.stopped == null, 'worker.stopped should be null');

    await worker.start();
    await Future.delayed(Duration(milliseconds: 5));
    expect(worker.started != null, 'worker.started should not be null');
    expect(
        worker.idleTime > Duration.zero, 'worker.idleTime should be positive');
    expect(worker.stopped == null, 'worker.stopped should be null');

    worker.stop();
    expect(worker.started != null, 'worker.started should not be null');
    expect(
        worker.idleTime > Duration.zero, 'worker.idleTime should be positive');
    expect(worker.stopped != null, 'worker.stopped should not be null');
  } on TestFailedException {
    rethrow;
  } catch (e) {
    throw TestFailedException('Unexpected exception: $e (${e.runtimeType})');
  }

  return true;
}
