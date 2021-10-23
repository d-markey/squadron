import 'package:squadron/squadron.dart';

import '../test/worker_services/rogue_service.dart';
import 'logger.dart';

final rogueWorkerTests = {
  'Worker Exception': testWorkerException,
  'Exception': testException,
};

Future<bool> testWorkerException(Logger logger) async {
  var success = false;

  final rogueWorker = RogueWorker('/sample_js_workers/rogue_worker.dart.js');
  await rogueWorker.start();

  try {
    final result = await rogueWorker.throwWorkerException();
    throw Exception('Unexpected result $result');
  } on WorkerException {
    success = true;
  } finally {
    rogueWorker.stop();
  }

  return success;
}

Future<bool> testException(Logger logger) async {
  var success = false;

  final rogueWorker = RogueWorker('/sample_js_workers/rogue_worker.dart.js');
  await rogueWorker.start();

  try {
    final result = await rogueWorker.throwException();
    throw Exception('Unexpected result $result');
  } on WorkerException {
    success = true;
  } finally {
    rogueWorker.stop();
  }

  return success;
}
