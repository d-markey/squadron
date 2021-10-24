import 'dart:async';

import 'package:squadron/squadron.dart';

import '../test/worker_services/sample_service.dart';

import 'expect.dart';
import 'logger.dart';

final sampleWorkerPoolTests = {'Sample Worker Pool': testSampleWorkerPool};

Future<bool> testSampleWorkerPool(Logger logger) async {
  final w = SampleService();

  const sampleTaskDuration = 500;
  const taskCount = 10;

  logger.log('running 2 x $taskCount tasks with a single worker...');

  final workerFutures = <Future>[];
  final workerSw = Stopwatch()..start();
  for (var i = 1; i <= taskCount; i++) {
    workerFutures.add(Future(() => w.cpu(milliseconds: sampleTaskDuration)));
    workerFutures.add(w.io(milliseconds: sampleTaskDuration));
  }
  await Future.wait(workerFutures);
  workerSw.stop();

  logger.log(
      'running 2 x $taskCount tasks with a single worker... completed in ${workerSw.elapsed}',
      replaceLastLine: true);

  final pool = WorkerPool<SampleWorker>(
      () => SampleWorker('/sample_js_workers/sample_worker.dart.js'),
      minWorkers: 1,
      maxWorkers: 4,
      maxParallel: 3);
  await pool.start();

  expect(pool.stats.where((s) => !s.isStopped).length == 1,
      'the pool should have one worker alive');

  logger.log('running 2 x $taskCount tasks with a worker pool...');

  final poolFutures = <Future>[];
  final poolSw = Stopwatch()..start();
  for (var i = 1; i <= taskCount; i++) {
    poolFutures.add(
        pool.compute((worker) => worker.cpu(milliseconds: sampleTaskDuration)));
    poolFutures.add(
        pool.compute((worker) => worker.io(milliseconds: sampleTaskDuration)));
  }
  await Future.wait(poolFutures);
  poolSw.stop();

  logger.log(
      'running 2 x $taskCount tasks with a worker pool... completed in ${poolSw.elapsed}',
      replaceLastLine: true);

  expect(poolSw.elapsedMicroseconds < workerSw.elapsedMicroseconds,
      'pool should complete faster than worker');

  pool.stop();
  expect(pool.stats.where((s) => !s.isStopped).isEmpty,
      'the pool should have no worker alive');

  return true;
}