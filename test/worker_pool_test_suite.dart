import 'dart:async';
import 'dart:math';

import 'package:test/test.dart';

import 'package:squadron/squadron.dart';

import 'worker_entry_points.dart';

import 'worker_services/cache_service_worker.dart';
import 'worker_services/pi_digits_service_worker.dart';
import 'worker_services/prime_service_worker.dart';
import 'worker_services/rogue_service_worker.dart';
import 'worker_services/sample_service_worker.dart';

void poolTests() {
  final timeFactor =
      5; // speed up tests; 10 seems to exceed time resolution on some hardware

  test('prime worker pool with cache', () async {
    final cache = CacheWorker(getEntryPoint('cache'));
    await cache.start();

    final maxWorkers = 4;
    final maxParallel = 2;
    final concurrencySettings =
        ConcurrencySettings(maxWorkers: maxWorkers, maxParallel: maxParallel);

    final pool = PrimeWorkerPool(
        getEntryPoint('prime'), cache.channel, concurrencySettings);

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

  test('worker pool monitoring', () async {
    var stopped = 0;
    final maxIdle = Duration(milliseconds: 1000 ~/ timeFactor);

    final minWorkers = 3;
    final maxWorkers = 11;
    final maxParallel = 2;
    final concurrencySettings = ConcurrencySettings(
        minWorkers: minWorkers,
        maxWorkers: maxWorkers,
        maxParallel: maxParallel);

    final pool = SampleWorkerPool(getEntryPoint('sample'), concurrencySettings);

    // start pool will instantiate 100 workers
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

    await Future.delayed(Duration(milliseconds: 250 ~/ timeFactor));

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

  test('exception handling from worker pool', () async {
    final maxWorkers = 4;
    final maxParallel = 2;
    final concurrencySettings =
        ConcurrencySettings(maxWorkers: maxWorkers, maxParallel: maxParallel);

    final pool = WorkerPool<RogueWorker>(
        () => RogueWorker(getEntryPoint('rogue')),
        concurrencySettings: concurrencySettings);
    await pool.start();

    try {
      await pool.execute((w) => w.throwWorkerException());
      // should never happen
      expect(false, isTrue);
    } on WorkerException catch (e) {
      // expected
      expect(e.message, equals('intended worker exception'));
      expect(e.stackTrace, contains('throwWorkerException'));
      expect(e.workerId, isNotNull);
    } catch (e) {
      // should never happen
      expect(e is WorkerException, isTrue);
      expect(false, isTrue);
    }
    expect(pool.stats.fold<int>(0, (p, s) => p + s.totalErrors), equals(1));

    try {
      await pool.execute((w) => w.throwException());
      // should never happen
      expect(false, isTrue);
    } on WorkerException catch (e) {
      // expected
      expect(e.message, contains('intended exception'));
      expect(e.stackTrace, contains('throwException'));
      expect(e.workerId, isNotNull);
    } catch (e) {
      // should never happen
      expect(e is WorkerException, isTrue);
      expect(false, isTrue);
    }
    expect(pool.stats.fold<int>(0, (p, s) => p + s.totalErrors), equals(2));

    pool.stop();
  });

  test('pi digits worker pool - futures', () async {
    final maxWorkers = 8;
    final concurrencySettings = ConcurrencySettings(maxWorkers: maxWorkers);

    final pool =
        PiDigitsWorkerPool(getEntryPoint('pi_digits'), concurrencySettings);

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

  test('pi digits worker pool - streams', () async {
    final maxWorkers = 8;
    final concurrencySettings = ConcurrencySettings(maxWorkers: maxWorkers);

    final pool =
        PiDigitsWorkerPool(getEntryPoint('pi_digits'), concurrencySettings);

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

  test('stopped pool will not accept new requests', () async {
    final concurrencySettings =
        ConcurrencySettings(minWorkers: 2, maxWorkers: 2, maxParallel: 3);

    final pool = SampleWorkerPool(getEntryPoint('sample'), concurrencySettings);
    await pool.start();

    final n = await pool.delayedIdentity(-1);
    expect(n, equals(-1));

    pool.stop();

    try {
      final n = await pool.delayedIdentity(-1);
      throw Exception('received $n although the pool has been stopped');
    } on SquadronException catch (ex) {
      expect(ex.message, contains('cannot accept new requests'));
      expect(ex.message, contains('stopped'));
    }
  });

  test('restarted pool will serve new requests', () async {
    final concurrencySettings =
        ConcurrencySettings(minWorkers: 2, maxWorkers: 2, maxParallel: 3);

    final pool = SampleWorkerPool(getEntryPoint('sample'), concurrencySettings);
    await pool.start();

    var n = await pool.delayedIdentity(-1);
    expect(n, equals(-1));

    pool.stop();

    try {
      n = await pool.delayedIdentity(-1);
      throw Exception('received $n although the pool has been stopped');
    } on SquadronException catch (ex) {
      expect(ex.message, contains('cannot accept new requests'));
      expect(ex.message, contains('stopped'));
    }

    pool.start(); // intentionally not awaited

    n = await pool.delayedIdentity(-2);
    expect(n, equals(-2));

    pool.stop();
  });

  test('pool termination does not prevent processing of pending tasks',
      () async {
    final concurrencySettings =
        ConcurrencySettings(minWorkers: 2, maxWorkers: 2, maxParallel: 3);

    final pool = SampleWorkerPool(getEntryPoint('sample'), concurrencySettings);
    await pool.start();

    final N = 2 *
        concurrencySettings.maxWorkers *
        (concurrencySettings.maxParallel + 1);
    final digits = <int>[];

    final tasks = <Future>[];
    for (var i = 0; i < N; i++) {
      tasks.add(pool.delayedIdentity(i).then((value) {
        digits.add(value);
      }));
    }
    await Future.delayed(Duration(milliseconds: 10));
    pool.stop();

    expect(pool.stopped, isTrue);
    expect(pool.pendingWorkload, isPositive);
    expect(digits.length, lessThan(N));

    await Future.wait(tasks);

    expect(pool.stopped, isTrue);
    expect(pool.pendingWorkload, isZero);
    expect(digits.length, equals(N));
  });
}
