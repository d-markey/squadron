import 'package:squadron/squadron.dart';

import '../test/worker_services/rogue_service_worker.dart';
import 'logger.dart';

final rogueWorkerTests = {
  'Worker Exception': testWorkerException,
  'Exception': testException,
};

Future<bool> testWorkerException(
    Logger logger, Map<String, String> entryPoints) async {
  var success = false;

  final rogueWorker = RogueWorker();
  await rogueWorker.start();

  try {
    await rogueWorker.throwWorkerException();
    throw Exception('throwWorkerException() completed successfully');
  } catch (ex) {
    success = (ex is WorkerException);
  } finally {
    rogueWorker.stop();
  }

  return success;
}

Future<bool> testException(
    Logger logger, Map<String, String> entryPoints) async {
  var success = false;

  final rogueWorker = RogueWorker();
  await rogueWorker.start();

  try {
    await rogueWorker.throwException();
    throw Exception('throwException() completed successfully');
  } catch (ex) {
    success = (ex is WorkerException);
  } finally {
    rogueWorker.stop();
  }

  return success;
}
