import 'dart:async';

import 'package:squadron/squadron.dart';

import 'identity_service.dart';
import 'sample_service.dart';
import 'sample_service_worker_pool.dart';
import 'sample_worker_vm.dart' as sample_isolate;

void main() async {
  final sw = Stopwatch()..start();

  Squadron.setId('MAIN');
  Squadron.debugMode = false;
  Squadron.logLevel = SquadronLogLevel.info;
  Squadron.setLogger(ConsoleSquadronLogger());

  void log([String? message]) {
    message ??= '';
    Squadron.info(message.isEmpty ? ' ' : '[${sw.elapsed}] $message');
  }

  final loops = 5;
  final max = 50;

  log();
  log('loops = $loops');
  log('max = $max');
  log();

  final identityService = IdentityServiceImpl();
  final identityServer = LocalWorker<IdentityService>.create(identityService);
  final identityClient = IdentityClient(identityServer.channel!.share());
  final sampleService = SampleServiceImpl(identityClient);

  SampleWorkerPool? pool;

  try {
    ///////////// SYNC /////////////
    log('///////////// SYNC /////////////');

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
    log();

    ///////////// POOL /////////////
    log('///////////// POOL /////////////');

    // create the pool
    final concurrencySettings =
        ConcurrencySettings(minWorkers: 2, maxWorkers: 4, maxParallel: 2);

    pool = SampleWorkerPool(
        sample_isolate.start, identityServer, concurrencySettings);
    await pool.start();
    log('pool started');

    // create the pool monitor
    final maxIdle = Duration(milliseconds: 500);
    final monitor = Timer.periodic(Duration(milliseconds: 250), (timer) {
      pool?.stop((w) => w.idleTime > maxIdle);
    });

    final tasks = <Future>[];

    // force maximum load on pool
    for (var i = 0; i < pool.maxWorkers; i++) {
      tasks.add(pool.cpu(milliseconds: 5));
    }

    await Future.wait(tasks);

    // 4 workers should have been started
    assert(pool.size == 4);
    // sit idle to that the pool monitor stops 2 of them
    await Future.delayed(maxIdle * 2);
    assert(pool.size == 2);
    log('pool monitor OK');

    final asyncSw = Stopwatch();
    asyncSw.start();
    for (var loop = 0; loop < loops; loop++) {
      final asyncFutures = <Future>[];
      for (var n = 0; n < max; n++) {
        asyncFutures.add(pool.cpu(milliseconds: n));
        asyncFutures.add(pool.io(milliseconds: n));
      }
      await Future.wait(asyncFutures);
    }
    asyncSw.stop();
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

    // stop the identity local worker
    identityServer.stop();

    // shutdown pool
    log('waiting for monitor to stop workers...');
    final sw = Stopwatch();
    sw.start();
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
      log('  * ${stat.id}: status=${stat.status}, workload=${stat.workload}, maxWorkload=${stat.maxWorkload}, totalWorkload=${stat.totalWorkload}, totalErrors=${stat.totalErrors}');
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
