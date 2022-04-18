import 'dart:async';
import 'dart:math';

import 'package:test/test.dart';

import 'package:squadron/squadron.dart';

import '../worker_services/cache_service_worker.dart';
import '../worker_services/failing_service_worker.dart';
import '../worker_services/pi_digits_service_worker.dart';
import '../worker_services/prime_service_worker.dart';
import '../worker_services/rogue_service_worker.dart';
import '../worker_services/test_service.dart';
import '../worker_services/test_service_worker.dart';

void poolTests() {
  final timeFactor =
      4; // speed up tests; 10 seems to exceed time resolution on some hardware

  test('- prime worker pool with cache', () async {
    final cache = CacheWorker();
    await cache.start();

    final maxWorkers = 4;
    final maxParallel = 2;
    final concurrencySettings =
        ConcurrencySettings(maxWorkers: maxWorkers, maxParallel: maxParallel);

    final pool = PrimeWorkerPool(cache, concurrencySettings);

    final completedTasks = <int>[];
    int taskId = 0;

    // start 1000 tasks
    final tasks = <Future>[];
    for (var i = 1; i <= 1000; i++) {
      var id = ++taskId;
      tasks.add(pool.isPrime(i).whenComplete(() => completedTasks.add(id)));
    }

    await Future.wait(tasks);

    expect(completedTasks.length, equals(tasks.length));

    final stats = pool.stats.toList();
    expect(stats.length, equals(maxWorkers));
    expect(stats.every((s) => s.maxWorkload <= maxParallel), isTrue);

    pool.stop();

    cache.stop();
  });

  test('- worker pool monitoring', () async {
    var stopped = 0;
    final maxIdle = Duration(milliseconds: 1000 ~/ timeFactor);

    final minWorkers = 3;
    final maxWorkers = 11;
    final maxParallel = 2;
    final concurrencySettings = ConcurrencySettings(
        minWorkers: minWorkers,
        maxWorkers: maxWorkers,
        maxParallel: maxParallel);

    final pool = TestWorkerPool(concurrencySettings);

    // start pool will instantiate 3 workers
    await pool.start();

    expect(pool.size, equals(minWorkers));

    // install worker monitor
    final timer =
        Timer.periodic(Duration(milliseconds: 200 ~/ timeFactor), (timer) {
      stopped += pool.stop((w) => !w.isStopped && w.idleTime > maxIdle);
    });

    final tasks = <Future>[];
    for (var i = 0; i < 2.5 * maxWorkers; i++) {
      tasks.add(pool.io(milliseconds: 2000 ~/ timeFactor));
    }

    await Future.delayed(Duration(milliseconds: 500 ~/ timeFactor));

    expect(pool.size, equals(maxWorkers));
    expect(stopped, equals(0));

    await Future.wait(tasks);

    await Future.delayed(Duration(milliseconds: 1000 ~/ timeFactor));

    expect(stopped, greaterThan(0));
    expect(stopped, lessThanOrEqualTo(maxWorkers - minWorkers));

    await Future.delayed(Duration(milliseconds: 1000 ~/ timeFactor));

    expect(stopped, equals(maxWorkers - minWorkers));

    timer.cancel();
    pool.stop();
  });

  test('- failing worker', () async {
    final pool = FailingWorkerPool(ConcurrencySettings.twoIoThreads);
    expect(() => pool.noop(), throwsA(isA<WorkerException>()));
  });

  test('- exception handling from worker pool', () async {
    final concurrencySettings =
        ConcurrencySettings(maxWorkers: 4, maxParallel: 2);

    final pool = RogueWorkerPool(concurrencySettings);

    try {
      await pool.execute((w) => w.throwWorkerException());
      // should never happen
      throw Exception('throwWorkerException completed successfully');
    } catch (ex) {
      expect(ex, isA<WorkerException>());
      final wex = ex as WorkerException;
      expect(wex.message, equals('intentional worker exception'));
      expect(wex.stackTrace?.toString(), contains('throwWorkerException'));
      expect(wex.workerId, isNotNull);
    }
    expect(pool.stats.fold<int>(0, (p, s) => p + s.totalErrors), equals(1));

    try {
      await pool.execute((w) => w.throwException());
      // should never happen
      throw Exception('throwException completed successfully');
    } catch (ex) {
      expect(ex, isA<WorkerException>());
      final wex = ex as WorkerException;
      expect(wex.message, contains('intentional exception'));
      expect(wex.stackTrace?.toString(), contains('throwException'));
      expect(wex.workerId, isNotNull);
    }
    expect(pool.stats.fold<int>(0, (p, s) => p + s.totalErrors), equals(2));

    pool.stop();
  });

  test('- pi digits worker pool - futures', () async {
    final maxWorkers = 8;
    final concurrencySettings = ConcurrencySettings(maxWorkers: maxWorkers);

    final pool = PiDigitsWorkerPool(concurrencySettings);

    final N = 50;
    final digits = <int, int>{};

    // start N tasks
    final tasks = <Future>[];
    for (var i = 0; i <= N; i++) {
      tasks.add(pool.getNth(i).then((digit) => digits[i] = digit));
    }

    await Future.wait(tasks);

    double valueOfPi = 0;
    double base = 1;
    for (var i = 0; i <= N; i++) {
      if (i > 0) base *= 16;
      valueOfPi += digits[i]! / base;
    }

    expect(valueOfPi, equals(pi));

    pool.stop();
  });

  test('- pi digits worker pool - streams', () async {
    final maxWorkers = 8;
    final concurrencySettings = ConcurrencySettings(maxWorkers: maxWorkers);

    final pool = PiDigitsWorkerPool(concurrencySettings);

    final N = 50;
    final batch = 10;
    final digits = <int, int>{};

    // start N / batch tasks
    final tasks = <Future>[];
    for (var i = 0; i <= N; i += batch) {
      tasks.add(pool.getNDigits(i, batch).toList().then((list) {
        for (var j = 0; j < batch; j++) {
          digits[i + j] = list[j];
        }
      }));
    }
    await Future.wait(tasks);

    double valueOfPi = 0;
    double base = 1;
    for (var i = 0; i <= N; i++) {
      if (i > 0) base *= 16;
      valueOfPi += digits[i]! / base;
    }

    expect(valueOfPi, equals(pi));

    pool.stop();
  });

  test('- pi digits worker pool - perf counter', () async {
    final pool = PiDigitsWorkerPool(ConcurrencySettings.sevenCpuThreads);

    final digits = <int, int>{};

    // start N tasks and measure performance
    final counter = PerfCounter('perf');
    final tasks = <Future>[];
    for (var i = 0; i <= 10 * pool.maxConcurrency; i++) {
      tasks.add(pool.getNth(i, counter).then((digit) => digits[i] = digit));
    }

    await tasks[0];

    final progress = counter.snapshot;

    await Future.wait(tasks);

    expect(progress.totalCount, lessThan(counter.totalCount));
    expect(progress.totalTimeInMicroseconds,
        lessThan(counter.totalTimeInMicroseconds));

    pool.stop();
  });

  test('- stopped pool will not accept new requests', () async {
    final pool = TestWorkerPool(ConcurrencySettings.oneIoThread);

    final n = await pool.delayed(-1);
    expect(n, equals(-1));

    pool.stop();

    try {
      final n = await pool.delayed(-1);
      // should never happen
      throw Exception('received $n although the pool has been stopped');
    } on SquadronError catch (ex) {
      expect(ex.message, contains('cannot accept new requests'));
      expect(ex.message, contains('stopped'));
    }
  });

  test('- restarted pool will serve new requests', () async {
    final pool = TestWorkerPool(ConcurrencySettings.twoIoThreads);

    var n = await pool.delayed(-1);
    expect(n, equals(-1));

    pool.stop();

    try {
      n = await pool.delayed(-1);
      // should never happen
      throw Exception('received $n although the pool has been stopped');
    } on SquadronError catch (ex) {
      expect(ex.message, contains('cannot accept new requests'));
      expect(ex.message, contains('stopped'));
    }

    // restart
    pool.start(); // intentionally not awaited

    n = await pool.delayed(-2);
    expect(n, equals(-2));

    pool.stop();
  });

  test('- pool termination does not prevent processing of pending tasks',
      () async {
    final pool = TestWorkerPool(ConcurrencySettings.threeCpuThreads);

    final N = 2 * pool.maxConcurrency + pool.maxWorkers;

    final digits = <int>[];
    final tasks = <Future>[];
    for (var i = 0; i < N; i++) {
      tasks.add(pool.delayed(i).then((value) {
        digits.add(value);
      }));
    }

    await Future.delayed(TestService.delay);
    pool.stop();

    expect(pool.stopped, isTrue);
    expect(pool.pendingWorkload, isPositive);
    expect(digits.length, lessThanOrEqualTo(pool.maxConcurrency * 3));

    await Future.wait(tasks);

    expect(pool.stopped, isTrue);
    expect(pool.pendingWorkload, isZero);
    expect(digits.length, equals(N));

    // give the scheduler a chance to really stop
    await Future.delayed(Duration.zero);

    expect(pool.size, isZero);
  });
}
