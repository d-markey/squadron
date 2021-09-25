import 'dart:async';

import 'package:squadron/squadron.dart';

import 'sample_worker.dart';

void main() async {
  final loops = 10;
  final max = 500;

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
      for (var n = 0; n <= max; n++) {
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

    pool = WorkerPool(() => SampleWorker(), maxWorkers: maxWorkers, maxParallel: maxParallel);
    await pool.start();

    final asyncTs = DateTime.now().microsecondsSinceEpoch;
    for (var loop = 0; loop < loops; loop++) {
      final asyncFutures = <Future>[];
      for (var n = 0; n <= max; n++) {
        asyncFutures.add(pool.compute((worker) => worker.cpuOperation(n)));
        asyncFutures.add(pool.compute((worker) => worker.ioOperation(n)));
      }
      await Future.wait(asyncFutures);
    }
    final asyncElapsed = DateTime.now().microsecondsSinceEpoch - asyncTs;

    print('async version completed in ${Duration(microseconds: asyncElapsed)}');
    for (var stat in pool.stats) {
      print('  * $stat');
    }
    print('');

  } on WorkerException catch (e) {
    print(e.message);
    print(e.stackTrace);
  } finally {
    pool?.stop();
  }

  print('');
}
