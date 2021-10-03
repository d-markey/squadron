import 'dart:async';

import 'package:squadron/squadron.dart';

import 'sample_worker.dart';
import 'worker_monitor.dart';

void main() async {
  final loops = 100;
  final max = 50;

  print('');
  print('loops = $loops');
  print('max = $max');
  print('');

  WorkerPool<SampleWorker>? pool;

  try {
    ///////////// SYNC /////////////
    print('///////////// SYNC /////////////');

    final syncTs = DateTime.now().microsecondsSinceEpoch;
    for (var loop = 0; loop < loops; loop++) {
      final syncFutures = <Future>[];
      for (var n = 0; n < max; n++) {
        syncFutures.add(Future.value(SampleWorker.cpuOperationImpl(n)));
        syncFutures.add(SampleWorker.ioOperationImpl(n));
      }
      await Future.wait(syncFutures);
    }
    final syncElapsed = DateTime.now().microsecondsSinceEpoch - syncTs;

    print('sync version completed in ${Duration(microseconds: syncElapsed)}');
    print('');

    ///////////// POOL /////////////
    print('///////////// POOL /////////////');

    final maxWorkers = 8;
    final maxParallel = 2;

    pool = WorkerPool(() => SampleWorker(),
        minWorkers: 1, maxWorkers: maxWorkers, maxParallel: maxParallel);
    await pool.start();

    final monitor = WorkerMonitor(pool, 100);
    monitor.start();

    final asyncTs = DateTime.now().microsecondsSinceEpoch;
    for (var loop = 0; loop < loops; loop++) {
      final asyncFutures = <Future>[];
      for (var n = 0; n < max; n++) {
        asyncFutures.add(
            Future.value(pool.compute((worker) => worker.cpuOperation(n))));
        asyncFutures.add(pool.compute((worker) => worker.ioOperation(n)));
      }
      await Future.wait(asyncFutures);
    }
    final asyncElapsed = DateTime.now().microsecondsSinceEpoch - asyncTs;

    print('async version completed in ${Duration(microseconds: asyncElapsed)}');

    print('waiting for monitor to stop workers...');
    final ts = DateTime.now().microsecondsSinceEpoch;
    var prevSize = 0;
    while (true) {
      final size = pool.size;
      if (prevSize != size) {
        print('   pool.size = $size');
        prevSize = size;
      }
      if (size == pool.minWorkers) break;
      await Future.delayed(monitor.maxIdle ~/ 500);
      if (DateTime.now().microsecondsSinceEpoch - ts >
          monitor.maxIdle.inMicroseconds * 2) {
        print('Houston, we\'ve got a problem...');
      }
    }

    print('worker stats:');
    for (var stat in pool.fullStats) {
      print('  * $stat');
    }

    monitor.stop();

    print('pool stats:');
    print(
        '  * load = ${pool.workload}, max load = ${pool.maxWorkload}, total load = ${pool.totalWorkload}, total errors = ${pool.totalErrors}');

    print('');
  } on WorkerException catch (e) {
    print(e.message);
    print(e.stackTrace);
  } finally {
    pool?.stop();
  }

  print('');
}
