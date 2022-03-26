import 'dart:async';

import 'package:squadron/squadron.dart';

import 'identity_service.dart';
import 'sample_service.dart';
import 'sample_service_worker_pool.dart';
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

  Squadron.setId('MAIN');

  final identityService = IdentityServiceImpl();
  final identityServer = LocalWorker<IdentityService>.create(identityService);
  final identityClient = IdentityClient(identityServer.channel!.share());
  log('IdentityClient is ${await identityClient.whoAreYou()}.');

  SampleWorkerPool? pool;

  try {
    final sampleService = SampleServiceImpl(identityClient);
    log(await sampleService.whoAreYouTalkingTo());

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
    log('');

    final minWorkers = 2;
    final maxWorkers = 4;
    final maxParallel = 2;

    final concurrencySettings = ConcurrencySettings(
        minWorkers: minWorkers,
        maxWorkers: maxWorkers,
        maxParallel: maxParallel);

    // create the pool
    pool = SampleWorkerPool(
        sample_isolate.start, identityServer, concurrencySettings);
    await pool.start();

    // create the pool monitor
    final maxIdle = Duration(seconds: 1);
    final monitor = Timer.periodic(Duration(milliseconds: 250), (timer) {
      pool?.stop((w) => w.idleTime > maxIdle);
    });

    final tasks = <Future>[];
    for (var i = 0;
        i <
            concurrencySettings.maxParallel * concurrencySettings.maxWorkers +
                1;
        i++) {
      tasks.add(pool.whoAreYouTalkingTo().then(print));
    }
    await Future.wait(tasks);

    // 4 workers should have been started
    // sit idle to that the pool monitor stops 2 of them
    await Future.delayed(maxIdle * 2);

    ///////////// POOL /////////////
    log('///////////// POOL /////////////');

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
      if (size <= pool.concurrencySettings.minWorkers) break;
      await Future.delayed(maxIdle ~/ 10);
      if (sw.elapsedMicroseconds > maxIdle.inMicroseconds * 2) {
        log('Houston, we have a problem...');
      }
    }

    log('worker stats:');
    for (var stat in pool.fullStats) {
      log('  * $stat');
    }

    monitor.cancel();

    log('pool stats:');
    log('  * load = ${pool.workload}, max load = ${pool.maxWorkload}, total load = ${pool.totalWorkload}, total errors = ${pool.totalErrors}');

    log('');
  } on WorkerException catch (e) {
    log(e.message);
    log(e.stackTrace.toString());
  } finally {
    pool?.stop();
  }

  // stop the identity local worker to stop the program!
  identityServer.stop();

  log('Done.');
  log('');
}
