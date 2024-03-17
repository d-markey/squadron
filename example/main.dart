import 'dart:async';

import 'package:logger/logger.dart';
import 'package:squadron/squadron.dart';

import 'identity_service.dart';
import 'sample_service.dart';
import 'sample_service_worker_pool.dart';
import 'sample_worker_vm.dart' as sample_isolate;
import 'thread_id.dart';

void main() async {
  final sw = Stopwatch()..start();

  final logger = Logger(level: Level.all);

  void log([String? message]) {
    message ??= '';
    print(message.isEmpty ? ' ' : '[${sw.elapsed}] $message');
    logger.i(message.isEmpty ? ' ' : '[${sw.elapsed}] $message');
  }

  final loops = 5;
  final max = 50;

  log();
  log('loops = $loops');
  log('max = $max');
  log('threadId = $threadId');
  log();

  final identityService = IdentityServiceImpl();
  final localIdentityWorker =
      LocalWorker<IdentityService>.create(identityService);
  final identityClient = IdentityClient(localIdentityWorker.channel!.share());
  final sampleService = SampleServiceImpl(identityClient);
  SampleWorkerPool? pool;

  Future<Stopwatch> measure(SampleService srv) async {
    final sw = Stopwatch()..start();
    for (var loop = 0; loop < loops; loop++) {
      final futures = <Future>[];
      for (var n = 0; n < max; n++) {
        futures
          ..add(Future(() => srv.cpu(milliseconds: n)))
          ..add(srv.io(milliseconds: n));
      }
      await Future.wait(futures);
    }
    sw.stop();
    return sw;
  }

  try {
    ///////////// SYNC /////////////
    log('///////////// SYNC /////////////');

    final syncSw = await measure(sampleService);
    final syncElapsed = syncSw.elapsedMicroseconds;

    log('sync version completed in ${Duration(microseconds: syncElapsed)}');
    log();

    ///////////// POOL /////////////
    log('///////////// POOL /////////////');

    // create the pool
    final concurrencySettings =
        ConcurrencySettings(minWorkers: 2, maxWorkers: 4, maxParallel: 2);

    void workerHook(PlatformThread worker) {
      log('Worker created with runtime type = ${worker.runtimeType}, threadId=$threadId');
    }

    pool = SampleWorkerPool(sample_isolate.start, localIdentityWorker,
        workerHook, concurrencySettings);
    pool.channelLogger = logger;
    await pool.start();
    log('pool started');

    // create the pool monitor
    final maxIdle = Duration(milliseconds: 1000);

    final monitor = Timer.periodic(Duration(milliseconds: 250), (timer) {
      pool?.stop((w) => w.idleTime > maxIdle);
    });

    log('pool monitor started');

    final tasks = <Future>[];

    // force maximum load on pool
    for (var i = 0; i < pool.maxConcurrency; i++) {
      tasks.add(pool.cpu(milliseconds: 5));
    }

    await Future.wait(tasks);

    // 4 workers should have been started
    assert(pool.size == 4);
    // sit idle to that the pool monitor stops 2 of them
    await Future.delayed(maxIdle * 2);
    assert(pool.size == 2);
    log('pool monitor OK');

    final asyncSw = await measure(pool);
    final asyncElapsed = asyncSw.elapsedMicroseconds;

    log('async version completed in ${Duration(microseconds: asyncElapsed)}');
    log();

    ///////////// LOCAL WORKER /////////////
    log('///////////// LOCAL WORKER /////////////');

    log('IdentityClient is ${await identityClient.whoAreYou()}.');
    log(await sampleService.whoAreYouTalkingTo());

    tasks.clear();
    for (var i = 0; i < pool.maxConcurrency + 1; i++) {
      tasks.add(pool.whoAreYouTalkingTo().then(log));
    }
    await Future.wait(tasks);

    // stop the local identity worker
    localIdentityWorker.stop();

    // shutdown pool
    log('waiting for monitor to stop workers...');
    final sw = Stopwatch()..start();
    while (true) {
      final size = pool.size;
      log('  * pool.size = $size');
      if (size <= pool.concurrencySettings.minWorkers) break;
      await Future.delayed(maxIdle ~/ 2);
      if (sw.elapsedMicroseconds > maxIdle.inMicroseconds * 2) {
        log('Houston, we have a problem...');
      }
    }

    log('worker stats:');
    for (var stat in pool.fullStats) {
      log('  * ${stat.workerHashCode}: status=${stat.status}, workload=${stat.workload}, maxWorkload=${stat.maxWorkload}, totalWorkload=${stat.totalWorkload}, totalErrors=${stat.totalErrors}');
    }

    monitor.cancel();

    log('pool stats:');
    log('  * size=${pool.size}, workload=${pool.workload}, maxLoad=${pool.maxWorkload}, totalWorkload=${pool.totalWorkload}, totalErrors=${pool.totalErrors}');

    log();
  } on WorkerException catch (e) {
    log(e.message);
    log(e.stackTrace?.toString());
  } finally {
    pool?.stop();
  }

  log('Done.');
  log();
}
