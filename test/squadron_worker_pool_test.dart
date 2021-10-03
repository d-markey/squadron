import 'dart:async';

import 'package:squadron/squadron.dart';
import 'package:test/test.dart';

import 'sample_workers/cache_worker.dart';
import 'sample_workers/dummy_worker.dart';
import 'sample_workers/prime_worker.dart';
import 'sample_workers/rogue_worker.dart';

void main() {
  final timeFactor =
      5; // speed up tests; 10 seems to exceed time resolution on some hardware

  test('prime worker pool with cache', () async {
    final cache = CacheWorker();
    await cache.start();

    final maxWorkers = 4;
    final maxParallel = 2;

    final pool = WorkerPool(() => PrimeWorker(cache),
        maxWorkers: maxWorkers, maxParallel: maxParallel);

    final completedTasks = <int>[];
    int taskId = 0;

    Future primeTest(int i) {
      var id = ++taskId;
      return pool.compute(
          (w) => w.isPrime(i).whenComplete(() => completedTasks.add(id)));
    }

    // start 1000 tasks
    final tasks = <Future>[];
    for (var i = 1; i <= 1000; i++) {
      tasks.add(primeTest(i));
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

    final pool = WorkerPool(() => DummyWorker(),
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
      tasks.add(pool.compute((w) => w.wait(milliseconds: 2000 ~/ timeFactor)));
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

    final pool = WorkerPool(() => RogueWorker(),
        maxWorkers: maxWorkers, maxParallel: maxParallel);
    await pool.start();

    try {
      final res = await pool.compute((w) => w.throwWorkerException());
      // should never happen
      expect(res, isNull);
      expect(false, isTrue);
    } on WorkerException catch (e) {
      // expected
      expect(true, isTrue);
      expect(e.message, equals('expected'));
      expect(e.stackTrace, contains('_throwWorkerExceptionImpl'));
      expect(e.workerId, isNotNull);
    } catch (e) {
      // should never happen
      expect(e is WorkerException, isTrue);
      expect(false, isTrue);
    }
    expect(pool.stats.fold<int>(0, (p, s) => p + s.totalErrors), equals(1));

    try {
      final res = await pool.compute((w) => w.throwException());
      // should never happen
      expect(res, isNull);
      expect(false, isTrue);
    } on WorkerException catch (e) {
      // expected
      expect(true, isTrue);
      expect(e.message, contains('unexpected'));
      expect(e.stackTrace, contains('_throwExceptionImpl'));
      expect(e.workerId, isNotNull);
    } catch (e) {
      // should never happen
      expect(e is WorkerException, isTrue);
      expect(false, isTrue);
    }
    expect(pool.stats.fold<int>(0, (p, s) => p + s.totalErrors), equals(2));

    pool.stop();
  });
}
