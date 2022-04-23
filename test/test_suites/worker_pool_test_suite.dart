import 'dart:async';

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

    final concurrencySettings =
        ConcurrencySettings(maxWorkers: 4, maxParallel: 2);

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
    expect(stats.length, equals(concurrencySettings.maxWorkers));
    expect(stats.every((s) => s.maxWorkload <= concurrencySettings.maxParallel),
        isTrue);

    pool.stop();

    cache.stop();
  });

  test('- worker pool monitoring', () async {
    var stopped = 0;

    final concurrencySettings =
        ConcurrencySettings(minWorkers: 3, maxWorkers: 11, maxParallel: 2);

    final pool = TestWorkerPool(concurrencySettings);

    // start pool will instantiate 3 workers
    await pool.start();

    expect(pool.size, equals(concurrencySettings.minWorkers));

    // install worker monitor
    final maxIdle = Duration(milliseconds: 1000 ~/ timeFactor);
    final timer =
        Timer.periodic(Duration(milliseconds: 200 ~/ timeFactor), (timer) {
      stopped += pool.stop((w) => !w.isStopped && w.idleTime > maxIdle);
    });

    final tasks = <Future>[];
    for (var i = 0; i < pool.maxConcurrency + 1; i++) {
      tasks.add(pool.io(milliseconds: 2000 ~/ timeFactor));
    }

    await Future.delayed(Duration(milliseconds: 500 ~/ timeFactor));

    expect(pool.size, equals(concurrencySettings.maxWorkers));
    expect(stopped, equals(0));

    await Future.wait(tasks);

    await Future.delayed(Duration(milliseconds: 1000 ~/ timeFactor));

    expect(stopped, greaterThan(0));
    expect(
        stopped,
        lessThanOrEqualTo(
            concurrencySettings.maxWorkers - concurrencySettings.minWorkers));

    await Future.delayed(Duration(milliseconds: 1000 ~/ timeFactor));

    expect(
        stopped,
        equals(
            concurrencySettings.maxWorkers - concurrencySettings.minWorkers));

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

  test('- exception handling from worker - TaskTimeOutException',
      () async {
    final pool = TestWorkerPool();

    try {
      await pool.timeOut();
      // should never happen
      throw Exception('timeOut() completed sucessfully');
    } catch (ex) {
      expect(ex, isA<TaskTimeoutException>());
      final wex = ex as TaskTimeoutException;
      expect(wex.message, contains('intentional timeout exception'));
    }

    pool.stop();
  });

  test('- exception handling from worker - CancelledException',
      () async {
    final pool = TestWorkerPool();

    try {
      await pool.cancelled();
      // should never happen
      throw Exception('cancel() completed sucessfully');
    } catch (ex) {
      expect(ex, isA<CancelledException>());
      final wex = ex as CancelledException;
      expect(wex.message, contains('intentional cancelled exception'));
    }

    pool.stop();
  });

  test('- pi digits worker pool - perf counter', () async {
    final pool = PiDigitsWorkerPool(ConcurrencySettings.sevenCpuThreads);

    final digits = <int, int>{};

    // start N tasks and measure performance
    final counter = PerfCounter('perf');
    final tasks = <Future>[];
    for (var i = 0; i < 3 * pool.maxConcurrency; i++) {
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

  group('- Streaming', () {
    test('- with multiple errors - cancelOnError: false', () async {
      final testWorkerPool = TestWorkerPool();

      final token = CancellationToken('by request');

      final done = Completer();
      final numbers = <int>[];
      final errors = <SquadronException>[];

      testWorkerPool.infiniteWithErrors(token).listen(
            (number) => numbers.add(number),
            onError: (ex) {
              errors.add(ex);
              if (errors.length > 3) {
                token.cancel();
              }
            },
            onDone: () => done.complete(),
            cancelOnError: false,
          );

      await done.future;

      expect(numbers.length, greaterThan(3 * 2));
      expect(errors.length, greaterThan(3));
      expect(errors.where((e) => e.message.contains('error #')).length,
          greaterThan(3));
      expect(errors.where((e) => e.message == token.message).length,
          greaterThanOrEqualTo(1));
    });

    test('- with multiple errors - cancelOnError: true', () async {
      final testWorkerPool = TestWorkerPool();

      final token = CancellationToken('by request');

      final numbers = <int>[];

      try {
        final future = testWorkerPool
            .infiniteWithErrors(token)
            .listen(
              (number) => numbers.add(number),
              cancelOnError: true,
            )
            .asFuture();
        await future;
        throw Exception('infiniteWithErrors() completed successfully');
      } catch (e) {
        expect(e, isA<WorkerException>());
        final ex = e as WorkerException;
        expect(ex.message, contains('error #'));
      }

      expect(numbers, equals([0, 1, 2]));
    });

    test('- with multiple errors - await for', () async {
      final testWorkerPool = TestWorkerPool();

      final token = CancellationToken('by request');

      final numbers = <int>[];

      try {
        await for (var number in testWorkerPool.infiniteWithErrors(token)) {
          numbers.add(number);
        }
        throw Exception('infiniteWithErrors() completed successfully');
      } catch (e) {
        expect(e, isA<WorkerException>());
        final ex = e as WorkerException;
        expect(ex.message, contains('error #'));
      }

      expect(numbers, equals([0, 1, 2]));
    });

    test('- with multiple errors - throwing in await for', () async {
      final testWorkerPool = TestWorkerPool();

      final token = CancellationToken('by request');

      final numbers = <int>[];

      try {
        await for (var number in testWorkerPool.infiniteWithErrors(token)) {
          if (numbers.isEmpty) {
            numbers.add(number);
          } else {
            throw WorkerException('Client-side exception');
          }
        }
        throw Exception('infiniteWithErrors() completed successfully');
      } catch (e) {
        expect(e, isA<WorkerException>());
        final ex = e as WorkerException;
        expect(ex.message, equals('Client-side exception'));
      }

      expect(numbers, equals([0]));
    });

    test('- with multiple errors - pause/resume', () async {
      final testWorkerPool = TestWorkerPool();

      final numbers = <int>[];
      final errors = <SquadronException>[];

      final token = CancellationToken('by request');
      final stream = testWorkerPool.infiniteWithErrors(token);
      final sub = stream.listen(
        (number) => numbers.add(number),
        onError: (ex) => errors.add(ex),
        cancelOnError: false,
      );

      int countNumbers = 0;
      int countErrors = 0;
      int paused = 0;

      void pause() {
        sub.pause();
        if (paused == 0) {
          expect(numbers.length, greaterThan(countNumbers));
          expect(errors.length, greaterThan(countErrors));
          countNumbers = numbers.length;
          countErrors = errors.length;
        } else {
          expect(numbers.length, equals(countNumbers));
          expect(errors.length, equals(countErrors));
        }
        paused++;
      }

      void resume() {
        expect(numbers.length, equals(countNumbers));
        expect(errors.length, equals(countErrors));
        sub.resume();
        if (paused > 0) {
          paused--;
        }
      }

      // this call should have no effect
      sub.resume();

      // pause immediately
      sub.pause();
      expect(numbers, isEmpty);
      expect(errors, isEmpty);
      await Future.delayed(TestService.delay * 3);
      expect(numbers, isEmpty);
      expect(errors, isEmpty);
      // resume
      sub.resume();

      await Future.delayed(TestService.delay * 3);
      pause();
      pause();
      await Future.delayed(TestService.delay * 3);
      resume();
      await Future.delayed(TestService.delay * 3);
      resume();
      await Future.delayed(TestService.delay * 3);

      sub.cancel();

      expect(numbers.length, greaterThan(countNumbers));
      expect(errors.length, greaterThan(countErrors));
      expect(errors.where((e) => e.message.contains('by request')), isEmpty);
    });

    test('- with multiple errors - pause/resume/cancel - using a StreamTask',
        () async {
      // at most one task
      final testWorkerPool = TestWorkerPool(
          ConcurrencySettings(maxParallel: 1, minWorkers: 1, maxWorkers: 1));
      expect(testWorkerPool.maxConcurrency, equals(1));

      final numbers0 = <int>[];
      final errors0 = <SquadronException>[];
      final token0 = CancellationToken('by request #0');
      final task0 = testWorkerPool.infiniteWithErrorsTask(token0);
      final stream0 = task0.stream;
      final sub0 = stream0.listen(
        (number) => numbers0.add(number),
        onError: (ex) => errors0.add(ex),
        cancelOnError: false,
      );

      // because concurrency settings only allow 1 task at a time, this task will not start streaming
      // before the previous one is finished
      final numbers1 = <int>[];
      final errors1 = <SquadronException>[];
      final token1 = CancellationToken('by request #1');
      final task1 = testWorkerPool.infiniteWithErrorsTask(token1);
      final stream1 = task1.stream;
      final sub1 = stream1.listen(
        (number) => numbers1.add(number),
        onError: (ex) => errors1.add(ex),
        cancelOnError: false,
      );

      sub0.pause();
      sub1.pause();

      await Future.delayed(TestService.delay * 3);

      expect(numbers0, isEmpty);
      expect(errors0, isEmpty);
      expect(numbers1, isEmpty);
      expect(errors1, isEmpty);

      sub0.resume();
      sub1.resume();

      await Future.delayed(TestService.delay * 3);

      expect(numbers0, isNotEmpty);
      expect(errors0, isNotEmpty);
      expect(numbers1, isEmpty);
      expect(errors1, isEmpty);

      // pause second stream, cancel first stream task
      sub1.pause();
      token0.cancel();

      final numbersCount0 = numbers0.length;
      final errorsCount0 = errors0.length;

      expect(numbers1, isEmpty);
      expect(errors1, isEmpty);

      // the second stream should be buffering events
      await Future.delayed(TestService.delay * 3);

      expect(numbers0.length, numbersCount0);
      expect(errors0.length, errorsCount0 + 1);
      expect(errors0.last.message, equals('by request #0'));
      expect(numbers1, isEmpty);
      expect(errors1, isEmpty);

      // resume: buffered event should be processed
      sub1.resume();
      await Future.delayed(Duration.zero);

      expect(numbers0.length, numbersCount0);
      expect(errors0.length, errorsCount0 + 1);
      expect(numbers1, isNotEmpty);
      expect(errors1, isNotEmpty);

      // terminate
      sub1.cancel();

      // /!\ cannot call getPendingInfiniteWithErrors() while task0 & task1 are still pending!
      final pending = await testWorkerPool.getPendingInfiniteWithErrors();
      expect(pending, isZero);

      List<int>? list;

      for (var i in list ?? []) {
        print(i);
      }
    });

    test('- with multiple errors - immediate cancellation', () async {
      final testWorkerPool = TestWorkerPool();

      final token = CancellationToken('by request');

      final numbers = <int>[];
      final errors = <SquadronException>[];

      final sub = testWorkerPool.infiniteWithErrors(token).listen(
            (number) => numbers.add(number),
            onError: (ex) => errors.add(ex),
            cancelOnError: false,
          );

      sub.cancel();

      await Future.delayed(TestService.delay * 3);

      expect(numbers, isEmpty);
      expect(errors, isEmpty);
    });
  });
}
