import 'dart:async';

import 'package:squadron/squadron_pool.dart';

import 'sample_service.dart';
import 'sample_service_worker.dart';
import 'worker_monitor.dart';
import 'sample_worker_vm.dart' as sample_isolate;

void main() async {
  final sw = Stopwatch()..start();

  void log(String message) {
    print(message.isEmpty ? '' : '[${sw.elapsed}] $message');
  }

  final loops = 5;
  final max = 50;

  log('');
  log('loops = $loops');
  log('max = $max');
  log('');

  WorkerPool<SampleWorker>? pool;

  try {
    ///////////// SYNC /////////////
    log('///////////// SYNC /////////////');

    final sampleService = SampleService();

    final syncSw = Stopwatch();
    syncSw.start();
    for (var loop = 0; loop < loops; loop++) {
      final syncFutures = <Future>[];
      for (var n = 0; n < max; n++) {
        syncFutures.add(Future(() => sampleService.cpu(milliseconds: n)));
        syncFutures.add(sampleService.io(milliseconds: n));
      }
      await Future.wait(syncFutures);
    }
    syncSw.stop();
    final syncElapsed = syncSw.elapsedMicroseconds;

    log('sync version completed in ${Duration(microseconds: syncElapsed)}');
    log('');

    ///////////// POOL /////////////
    log('///////////// POOL /////////////');

    final minWorkers = 2;
    final maxWorkers = 4;
    final maxParallel = 2;

    pool = WorkerPool(() => SampleWorker(sample_isolate.start),
        minWorkers: minWorkers,
        maxWorkers: maxWorkers,
        maxParallel: maxParallel);
    await pool.start();

    final monitor = WorkerMonitor(pool, maxIdleInMilliseconds: 250);
    monitor.start();

    final asyncSw = Stopwatch();
    asyncSw.start();
    for (var loop = 0; loop < loops; loop++) {
      final asyncFutures = <Future>[];
      for (var n = 0; n < max; n++) {
        asyncFutures.add(pool.compute((worker) => worker.cpu(milliseconds: n)));
        asyncFutures.add(pool.compute((worker) => worker.io(milliseconds: n)));
      }
      await Future.wait(asyncFutures);
    }
    asyncSw.stop();
    final asyncElapsed = asyncSw.elapsedMicroseconds;

    log('async version completed in ${Duration(microseconds: asyncElapsed)}');

    log('waiting for monitor to stop workers...');
    final sw = Stopwatch();
    sw.start();
    var prevSize = 0;
    while (true) {
      final size = pool.size;
      if (prevSize != size) {
        log('   pool.size = $size');
        prevSize = size;
      }
      if (size == pool.minWorkers) break;
      await Future.delayed(monitor.maxIdle ~/ 500);
      if (sw.elapsedMicroseconds > monitor.maxIdle.inMicroseconds * 2) {
        log('Houston, we\'ve got a problem...');
      }
    }

    log('worker stats:');
    for (var stat in pool.fullStats) {
      log('  * $stat');
    }

    monitor.stop();

    log('pool stats:');
    log('  * load = ${pool.workload}, max load = ${pool.maxWorkload}, total load = ${pool.totalWorkload}, total errors = ${pool.totalErrors}');

    log('');
  } on WorkerException catch (e) {
    log(e.message);
    log(e.stackTrace.toString());
  } finally {
    pool?.stop();
  }

  log('Done.');
  log('');
}
