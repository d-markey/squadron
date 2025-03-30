import 'dart:async';

import 'package:squadron/squadron.dart';

import 'logging_service.dart';
import 'sample_service.dart';
import 'sample_service_worker_pool.dart';
import 'sample_worker_vm.dart' as sample_isolate;

void main() async {
  final loggingService = LoggingServiceImpl();
  final localLoggingWorker = LocalWorker.create(loggingService);
  final loggingClient = LoggingClient(localLoggingWorker.channel!);
  final sampleService = SampleServiceImpl(loggingClient);
  SampleWorkerPool? pool;

  final loops = 2;
  final max = 10;

  loggingService.log(threadId, '');
  loggingService.log(threadId, 'loops = $loops');
  loggingService.log(threadId, 'max = $max');
  loggingService.log(threadId, 'threadId = $threadId');
  loggingService.log(threadId, '');

  Future<Stopwatch> measure(SampleService srv) async {
    final sw = Stopwatch()..start();
    for (var loop = 0; loop < loops; loop++) {
      final futures = <Future>[];
      for (var n = 0; n < max; n++) {
        futures
          ..add(Future(() => srv.cpu(milliseconds: (n + 1) * 20)))
          ..add(srv.io(milliseconds: (n + 1) * 20));
      }
      await Future.wait(futures);
    }
    sw.stop();
    return sw;
  }

  try {
    ///////////// SYNC /////////////
    loggingService.log(threadId, '///////////// SYNC /////////////');

    final syncSw = await measure(sampleService);
    final syncElapsed = syncSw.elapsedMicroseconds;

    loggingService.log(threadId,
        'sync version completed in ${Duration(microseconds: syncElapsed)}');
    loggingService.log(threadId, '');

    ///////////// POOL /////////////
    loggingService.log(threadId, '///////////// POOL /////////////');

    // create the pool
    final concurrencySettings =
        ConcurrencySettings(minWorkers: 2, maxWorkers: 4, maxParallel: 2);

    void workerHook(PlatformThread worker) {
      loggingService.log(
          threadId, 'Worker created with runtime type = ${worker.runtimeType}');
    }

    pool = SampleWorkerPool(sample_isolate.start, localLoggingWorker,
        workerHook, concurrencySettings);
    await pool.start();
    loggingService.log(threadId, 'pool started');

    // create the pool monitor
    final maxIdle = Duration(milliseconds: 1000);

    final monitor = Timer.periodic(Duration(milliseconds: 250), (timer) {
      pool?.stop((w) => w.getStats().idleTime > maxIdle);
    });

    loggingService.log(threadId, 'pool monitor started');

    final tasks = <Future>[];

    // force maximum load on pool
    for (var i = 0; i < pool.concurrencySettings.maxConcurrency; i++) {
      tasks.add(pool.cpu(milliseconds: 20));
    }

    await Future.wait(tasks);

    // 4 workers should have been started
    assert(pool.size == 4);
    // sit idle to that the pool monitor stops 2 of them
    await Future.delayed(maxIdle * 2);
    assert(pool.size == 2);
    loggingService.log(threadId, 'pool monitor OK');

    final asyncSw = await measure(pool);
    final asyncElapsed = asyncSw.elapsedMicroseconds;

    loggingService.log(threadId,
        'async version completed in ${Duration(microseconds: asyncElapsed)}');
    loggingService.log(threadId, '');

    // shutdown pool
    loggingService.log(threadId, 'waiting for monitor to stop workers...');
    final sw = Stopwatch()..start();
    while (true) {
      final size = pool.size;
      loggingService.log(threadId, '  * pool.size = $size');
      if (size <= pool.concurrencySettings.minWorkers) break;
      await Future.delayed(maxIdle ~/ 2);
      if (sw.elapsedMicroseconds > maxIdle.inMicroseconds * 2) {
        loggingService.log(threadId, 'Houston, we have a problem...');
      }
    }

    loggingService.log(threadId, 'worker stats:');
    for (var stat in pool.fullStats) {
      loggingService.log(threadId,
          '  * ${stat.workerHashCode.hex}: status=${stat.status}, workload=${stat.workload}, maxWorkload=${stat.maxWorkload}, totalWorkload=${stat.totalWorkload}, totalErrors=${stat.totalErrors}');
    }

    monitor.cancel();

    loggingService.log(threadId, 'pool stats:');
    final stats = pool.stats.toList(), fullStats = pool.fullStats.toList();
    loggingService.log(threadId,
        '  * size=${pool.size}, workload=${stats.workload}, totalWorkload=${fullStats.totalWorkload}, totalErrors=${fullStats.totalErrors}');

    loggingService.log(threadId, '');
  } on WorkerException catch (e) {
    loggingService.log(threadId, e.message);
    loggingService.log(threadId, (e.stackTrace ?? StackTrace.empty).toString());
  } finally {
    pool?.stop();
  }

  // stop the local identity worker
  loggingService.log(threadId, 'Stopping the local worker...');
  localLoggingWorker.terminate();

  loggingService.log(threadId, '');
  loggingService.log(threadId, 'Done.');
}

extension WorkerStatExt on WorkerStat {
  String get status {
    if (isStopped) {
      return 'STOPPED';
    } else if (workload == 0) {
      return 'IDLE';
    } else {
      return 'WORKING($workload)';
    }
  }
}
