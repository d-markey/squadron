import 'dart:async';
import 'dart:html';

import 'expect.dart';
import 'logger.dart';
import '../test/worker_services/sample_service_worker.dart';

final sampleWorkerTests = {
  'Sample Worker - start / stop': testSampleWorkerStartStop,
  'Raw Worker - test': testRawWorker,
};

Future<bool> testSampleWorkerStartStop(
    Logger logger, Map<String, String> entryPoints) async {
  try {
    final worker = SampleWorker();
    expect(worker.upTime == Duration.zero, 'worker.upTime should be zero');
    expect(worker.idleTime == Duration.zero, 'worker.idleTime should be zero');
    expect(worker.isStopped == false, 'worker.isStopped should be false');

    await worker.start();
    await Future.delayed(Duration(milliseconds: 5));
    expect(
        worker.upTime > Duration.zero, 'worker.upTime should not be positive');
    expect(
        worker.idleTime > Duration.zero, 'worker.idleTime should be positive');
    expect(worker.isStopped == false, 'worker.isStopped should be false');

    worker.stop();
    expect(
        worker.upTime > Duration.zero, 'worker.upTime should not be positive');
    expect(
        worker.idleTime > Duration.zero, 'worker.idleTime should be positive');
    expect(worker.isStopped == true, 'worker.isStopped should be true');
  } on TestFailedException {
    rethrow;
  } catch (e) {
    throw TestFailedException('Unexpected exception: $e (${e.runtimeType})');
  }

  return true;
}

Future<bool> testRawWorker(
    Logger logger, Map<String, String> entryPoints) async {
  try {
    final worker = Worker(entryPoints['echo']!);

    final completer = Completer<String>();

    worker.onError.listen((error) {
      completer.complete('Error in Web Worker listener: $error');
    });
    worker.onMessage.listen((event) {
      completer.complete(event.data);
    });

    worker.postMessage('Hello');

    final result = await completer.future;
    expect(result == 'ECHO "Hello"',
        'raw worker should reply with the original message content between double quotes');

    worker.terminate();
  } on TestFailedException {
    rethrow;
  } catch (e) {
    throw TestFailedException('Unexpected exception: $e (${e.runtimeType})');
  }

  return true;
}
