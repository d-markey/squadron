import 'dart:async';
import 'dart:math';

import 'package:squadron/squadron_pool.dart';
import 'package:test/test.dart';

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

    final pool = WorkerPool(
        () => PrimeWorker(getEntryPoint('prime'),
            args: [cache.channel?.share().serialize()]),
        maxWorkers: maxWorkers,
        maxParallel: maxParallel);

    final completedTasks = <int>[];
    final completedComputes = <int>[];
    int taskId = 0;

    // start 1000 tasks
    final tasks = <Future>[];
    for (var i = 1; i <= 1000; i++) {
      var id = ++taskId;
      tasks.add(pool
          .compute(
              (w) => w.isPrime(i).whenComplete(() => completedTasks.add(id)))
          .whenComplete(() => completedComputes.add(id)));
    }

    await Future.wait(tasks);

    expect(completedTasks.length, equals(tasks.length));
    expect(completedComputes.length, equals(tasks.length));

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

    final pool = WorkerPool(() => SampleWorker(getEntryPoint('sample')),
        minWorkers: minWorkers,
        maxWorkers: maxWorkers,
        maxParallel: maxParallel);

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
      tasks.add(pool.compute((w) => w.io(milliseconds: 2000 ~/ timeFactor)));
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

    final pool = WorkerPool<RogueWorker>(
        () => RogueWorker(getEntryPoint('rogue')),
        maxWorkers: maxWorkers,
        maxParallel: maxParallel);
    await pool.start();

    try {
      await pool.compute((w) => w.throwWorkerException());
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
      await pool.compute((w) => w.throwException());
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

  test('pi digits worker pool', () async {
    final maxWorkers = 8;

    final pool = WorkerPool(() => PiDigitsWorker(getEntryPoint('pi_digits')),
        maxWorkers: maxWorkers);

    final N = 50;
    final digits = <int, int>{};

    // start N tasks
    final tasks = <Future>[];
    for (var i = 0; i <= N; i++) {
      tasks.add(
          pool.compute((w) => w.getNth(i).then((digit) => digits[i] = digit)));
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
}
