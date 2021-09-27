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

  test('start & stop', () async {
    final dummy = DummyWorker();

    await Future.delayed(Duration(milliseconds: 5));
    expect(dummy.commandPort, isNull);
    expect(dummy.started, isNull);
    expect(dummy.stopped, isNull);
    expect(dummy.upTime, Duration.zero);
    expect(dummy.idleTime, Duration.zero);

    await dummy.start();
    expect(dummy.commandPort, isNotNull);

    await Future.delayed(Duration(milliseconds: 5));
    expect(dummy.started, isNotNull);
    expect(dummy.stopped, isNull);
    var upTime = dummy.upTime;
    expect(upTime, greaterThan(Duration.zero));
    expect(dummy.idleTime, greaterThanOrEqualTo(upTime));

    dummy.stop();
    upTime = dummy.upTime;
    expect(dummy.commandPort, isNull);
    expect(dummy.started, isNotNull);
    expect(dummy.stopped, isNotNull);
    expect(dummy.stopped!.isAfter(dummy.started!), isTrue);

    await Future.delayed(Duration(milliseconds: 5));
    expect(dummy.upTime, equals(upTime));
    expect(
        dummy.upTime,
        equals(Duration(
            microseconds: dummy.stopped!.microsecondsSinceEpoch -
                dummy.started!.microsecondsSinceEpoch)));
    expect(dummy.idleTime.inMicroseconds,
        greaterThan(dummy.upTime.inMicroseconds));
  });

  test('workload - sequential', () async {
    final dummy = DummyWorker();
    final completedTasks = <int>[];
    int taskId = 0;

    Future createDummyTask({required int milliseconds}) {
      var id = ++taskId;
      return dummy
          .wait(milliseconds: milliseconds)
          .whenComplete(() => completedTasks.add(id));
    }

    await Future.delayed(Duration(milliseconds: 5));

    expect(completedTasks, equals([]));
    expect(dummy.workload, isZero);
    expect(dummy.maxWorkload, isZero);
    expect(dummy.totalWorkload, isZero);

    await dummy.start();

    expect(completedTasks, equals([]));
    expect(dummy.workload, isZero);
    expect(dummy.maxWorkload, isZero);
    expect(dummy.totalWorkload, isZero);

    await createDummyTask(milliseconds: 200 ~/ timeFactor); // task 1

    expect(completedTasks, equals([1]));
    expect(dummy.workload, equals(0));
    expect(dummy.maxWorkload, equals(1));
    expect(dummy.totalWorkload, equals(1));

    var task = createDummyTask(milliseconds: 300 ~/ timeFactor); // task 2

    expect(completedTasks, equals([1]));
    expect(dummy.workload, equals(1));
    expect(dummy.maxWorkload, equals(1));
    expect(dummy.totalWorkload, equals(1));

    await Future.delayed(Duration(milliseconds: 100 ~/ timeFactor));

    expect(completedTasks, equals([1]));
    expect(dummy.workload, equals(1));
    expect(dummy.maxWorkload, equals(1));
    expect(dummy.totalWorkload, equals(1));

    await task;

    expect(completedTasks, equals([1, 2]));
    expect(dummy.workload, equals(0));
    expect(dummy.maxWorkload, equals(1));
    expect(dummy.totalWorkload, equals(2));

    await createDummyTask(milliseconds: 200 ~/ timeFactor); // task 3

    expect(completedTasks, equals([1, 2, 3]));
    expect(dummy.workload, equals(0));
    expect(dummy.maxWorkload, equals(1));
    expect(dummy.totalWorkload, equals(3));

    dummy.stop();

    expect(dummy.workload, equals(0));
    expect(dummy.maxWorkload, equals(1));
    expect(dummy.totalWorkload, equals(3));
  });

  test('workload - parallel', () async {
    final dummy = DummyWorker();
    final completedTasks = <int>[];
    int taskId = 0;

    Future createDummyTask({required int milliseconds}) {
      var id = ++taskId;
      return dummy
          .wait(milliseconds: milliseconds)
          .whenComplete(() => completedTasks.add(id));
    }

    await Future.delayed(Duration(milliseconds: 5));

    expect(completedTasks, equals([]));
    expect(dummy.workload, isZero);
    expect(dummy.maxWorkload, isZero);
    expect(dummy.totalWorkload, isZero);

    await dummy.start();

    expect(completedTasks, equals([]));
    expect(dummy.workload, isZero);
    expect(dummy.maxWorkload, isZero);
    expect(dummy.totalWorkload, isZero);

    var tasks = [
      createDummyTask(milliseconds: 200 ~/ timeFactor), // task 1
      createDummyTask(milliseconds: 300 ~/ timeFactor), // task 2
      createDummyTask(milliseconds: 250 ~/ timeFactor), // task 3
    ];

    expect(completedTasks, equals([]));
    expect(dummy.workload, equals(3));
    expect(dummy.maxWorkload, equals(3));
    expect(dummy.totalWorkload, equals(0));

    await Future.wait(tasks);

    expect(completedTasks, equals([1, 3, 2]));
    expect(dummy.workload, equals(0));
    expect(dummy.maxWorkload, equals(3));
    expect(dummy.totalWorkload, equals(3));

    /////////// 0 ms: time origin for next tasks ///////////

    createDummyTask(
        milliseconds: 800 ~/ timeFactor); // task 4 to be completed at ~800 ms
    createDummyTask(
        milliseconds: 600 ~/ timeFactor); // task 5 to be completed at ~600 ms
    createDummyTask(
        milliseconds: 400 ~/ timeFactor); // task 6 to be completed at ~400 ms

    expect(completedTasks, equals([1, 3, 2]));
    expect(dummy.workload, equals(3));
    expect(dummy.maxWorkload, equals(3));
    expect(dummy.totalWorkload, equals(3));

    await Future.delayed(Duration(
        milliseconds: 250 ~/ timeFactor)); // 250 ms: all tasks still pending

    expect(completedTasks, equals([1, 3, 2]));
    expect(dummy.workload, equals(3));
    expect(dummy.maxWorkload, equals(3));
    expect(dummy.totalWorkload, equals(3));

    await Future.delayed(Duration(
        milliseconds: 450 ~/
            timeFactor)); // 700 ms: tasks 6 & 5 finished, 4 still pending

    expect(completedTasks, equals([1, 3, 2, 6, 5]));
    expect(dummy.workload, equals(1));
    expect(dummy.maxWorkload, equals(3));
    expect(dummy.totalWorkload, equals(5));

    createDummyTask(
        milliseconds: 600 ~/ timeFactor); // task 7 to be completed at ~1300 ms
    createDummyTask(
        milliseconds: 200 ~/ timeFactor); // task 8 to be completed at ~900 ms

    expect(completedTasks, equals([1, 3, 2, 6, 5]));
    expect(dummy.workload, equals(3));
    expect(dummy.maxWorkload, equals(3));
    expect(dummy.totalWorkload, equals(5));

    await Future.delayed(Duration(
        milliseconds: 350 ~/
            timeFactor)); // 1050 ms: tasks 4 & 8 finished, 7 still pending

    expect(completedTasks, equals([1, 3, 2, 6, 5, 4, 8]));
    expect(dummy.workload, equals(1));
    expect(dummy.maxWorkload, equals(3));
    expect(dummy.totalWorkload, equals(7));

    await Future.delayed(Duration(
        milliseconds: 350 ~/ timeFactor)); // 1400 ms: all tasks finished

    expect(completedTasks, equals([1, 3, 2, 6, 5, 4, 8, 7]));
    expect(dummy.workload, equals(0));
    expect(dummy.maxWorkload, equals(3));
    expect(dummy.totalWorkload, equals(8));

    dummy.stop();
    expect(dummy.workload, equals(0));
    expect(dummy.maxWorkload, equals(3));
    expect(dummy.totalWorkload, equals(8));
  });

  test('cache worker', () async {
    final cache = CacheWorker();
    await cache.start();

    expect(await cache.get(1), isNull);
    expect(await cache.containsKey(1), isFalse);
    await cache.set(1, 'in cache');
    expect(await cache.containsKey(1), isTrue);
    expect(await cache.get(1), 'in cache');

    cache.stop();
    expect(cache.stopped, isNotNull);
  });

  test('prime worker', () async {
    final primeWorker = PrimeWorker();
    await primeWorker.start();

    for (var i = 1; i < 1000; i++) {
      expect(
          await primeWorker.isPrime(i), PrimeWorker.primesTo1000.contains(i));
    }

    primeWorker.stop();
    expect(primeWorker.stopped, isNotNull);
  });

  test('prime worker - stream', () async {
    final primeWorker = PrimeWorker();
    await primeWorker.start();

    final computedPrimes = await primeWorker.getPrimes(1, 1000).toList();

    expect(computedPrimes, equals(PrimeWorker.primesTo1000));

    primeWorker.stop();
    expect(primeWorker.stopped, isNotNull);
  });

  test('prime worker with cache', () async {
    final cache = CacheWorker();
    await cache.start();

    final primeWorker = PrimeWorker(cache);
    await primeWorker.start();

    for (var i = 1; i < 1000; i++) {
      expect(
          await primeWorker.isPrime(i), PrimeWorker.primesTo1000.contains(i));
    }
    final computedPrimes = await primeWorker.getPrimes(1, 1000).toList();

    expect(computedPrimes, equals(PrimeWorker.primesTo1000));

    primeWorker.stop();
    expect(primeWorker.stopped, isNotNull);

    cache.stop();
    expect(cache.stopped, isNotNull);
  });

  test('prime worker with cache - perf', () async {
    final cache = CacheWorker();
    await cache.start();

    final primeWorker = PrimeWorker(cache);
    await primeWorker.start();

    var firstPerf = PerfCounter('with empty cache');
    await firstPerf.measure(() async {
      for (var prime in PrimeWorker.largePrimes) {
        expect(await primeWorker.isPrime(prime), isTrue);
      }
    });

    var secondPerf = PerfCounter('with full cache');
    await secondPerf.measure(() async {
      for (var prime in PrimeWorker.largePrimes) {
        expect(await primeWorker.isPrime(prime), isTrue);
      }
    });

    expect(secondPerf.totalTimeInMicroseconds,
        lessThan(firstPerf.totalTimeInMicroseconds));
    expect(
        secondPerf.totalTimeInMicroseconds / firstPerf.totalTimeInMicroseconds,
        lessThan(0.1));

    primeWorker.stop();
    expect(primeWorker.stopped, isNotNull);

    cache.stop();
    expect(cache.stopped, isNotNull);
  });

  test('exception handling from worker', () async {
    final rogue = RogueWorker();

    try {
      final res = await rogue.throwWorkerException();
      // should never happen
      expect(res, isNull);
      expect(false, isTrue);
    } on WorkerException catch (e) {
      // expected exception
      expect(true, isTrue);
      expect(e.message, equals('expected'));
      expect(e.stackTrace, contains('_throwWorkerExceptionImpl'));
      expect(e.workerId, isNotNull);
    } catch (e) {
      // should never happen
      expect(e is WorkerException, isTrue);
      expect(false, isTrue);
    }
    expect(rogue.stats.totalErrors, equals(1));

    try {
      final res = await rogue.throwException();
      // should never happen
      expect(res, isNull);
      expect(false, isTrue);
    } on WorkerException catch (e) {
      // expected exception
      expect(true, isTrue);
      expect(e.message, contains('unexpected'));
      expect(e.stackTrace, contains('_throwExceptionImpl'));
      expect(e.workerId, isNotNull);
    } catch (e) {
      // should never happen
      expect(e is WorkerException, isTrue);
      expect(false, isTrue);
    }
    expect(rogue.stats.totalErrors, equals(2));

    rogue.stop();
  });
}
