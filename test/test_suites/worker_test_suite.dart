import 'dart:async';

import 'package:squadron/squadron.dart';
import 'package:test/test.dart';

import '../classes/custom_exception.dart';
import '../classes/prime_numbers.dart';
import '../classes/untransferable.dart';
import '../worker_services/bitcoin_service_worker.dart';
import '../worker_services/cache_service_worker.dart';
import '../worker_services/failing_service_worker.dart';
import '../worker_services/invalid_service_worker.dart';
import '../worker_services/prime_service_worker.dart';
import '../worker_services/rogue_service.dart';
import '../worker_services/rogue_service_worker.dart';
import '../worker_services/test_service.dart';
import '../worker_services/test_service_worker.dart';

void workerTests() {
  final timeFactor =
      4; // speed up tests; 10 seems to exceed time resolution on some hardware

  test('- start & stop', () async {
    final dummy = TestWorker();

    await Future.delayed(Duration(milliseconds: 5));
    expect(dummy.channel, isNull);
    expect(dummy.upTime, Duration.zero);
    expect(dummy.idleTime, Duration.zero);
    expect(dummy.isStopped, isFalse);

    final channel = await dummy.start();
    expect(dummy.channel, isNotNull);
    expect(channel, equals(dummy.channel));

    await Future.delayed(Duration(milliseconds: 5));
    expect(dummy.upTime, greaterThan(Duration.zero));
    expect(dummy.isStopped, false);
    var upTime = dummy.upTime;
    expect(upTime, greaterThan(Duration.zero));
    expect(dummy.idleTime, greaterThanOrEqualTo(upTime));

    dummy.stop();
    upTime = dummy.upTime;
    expect(dummy.channel, isNull);
    expect(dummy.upTime, greaterThan(Duration.zero));
    expect(dummy.isStopped, isTrue);

    await Future.delayed(Duration(milliseconds: 5));
    expect(dummy.upTime, equals(upTime));
    expect(dummy.idleTime.inMicroseconds,
        greaterThan(dummy.upTime.inMicroseconds));
  });

  test('- start & stop - cannot restart', () async {
    final dummy = TestWorker();

    await dummy.start();

    await Future.delayed(Duration(milliseconds: 5));

    dummy.stop();

    await Future.delayed(Duration(milliseconds: 5));

    try {
      await dummy.start();
      // should never happen
      throw Exception('stopped channel restarted successfully');
    } catch (ex) {
      expect(ex, isA<WorkerException>());
    }
  });

  test('- workload - sequential', () async {
    final dummy = TestWorker();
    final completedTasks = <int>[];
    int taskId = 0;

    Future createDummyTask({required int milliseconds}) {
      var id = ++taskId;
      return dummy
          .io(milliseconds: milliseconds)
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

  test('- workload - parallel', () async {
    final dummy = TestWorker();
    final completedTasks = <int>[];
    int taskId = 0;

    Future createDummyTask({required int milliseconds}) {
      var id = ++taskId;
      return dummy
          .io(milliseconds: milliseconds)
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

  test('- cache worker', () async {
    final cache = CacheWorker();

    expect(await cache.get(1), isNull);
    expect(await cache.containsKey(1), isFalse);
    await cache.set(1, 'in cache');
    expect(await cache.containsKey(1), isTrue);
    expect(await cache.get(1), 'in cache');

    cache.stop();
    expect(cache.isStopped, isTrue);
  });

  test('- prime worker', () async {
    final primeWorker = PrimeWorker();

    for (var i = 1; i < 1000; i++) {
      expect(await primeWorker.isPrime(i), primesTo1000.contains(i));
    }

    primeWorker.stop();
    expect(primeWorker.isStopped, isTrue);
  });

  test('- prime worker with cache', () async {
    final cache = CacheWorker();
    await cache.start();

    final initialStats = await cache.getStats();

    expect(initialStats.hit, isZero);
    expect(initialStats.miss, isZero);
    expect(initialStats.expired, isZero);
    expect(initialStats.size, isZero);
    expect(initialStats.maxSize, isZero);

    final primeWorker = PrimeWorker(cache);

    for (var i = 1; i < 1000; i++) {
      expect(await primeWorker.isPrime(i), primesTo1000.contains(i));
    }
    final computedPrimes = await primeWorker.getPrimes(1, 1000).toList();

    expect(computedPrimes, equals(primesTo1000));

    primeWorker.stop();
    expect(primeWorker.isStopped, isTrue);

    final stats = await cache.getStats();
    expect(stats.hit, isPositive);
    expect(stats.miss, isPositive);
    expect(stats.expired, isZero);
    expect(stats.size, isPositive);
    expect(stats.maxSize, equals(stats.size));

    cache.stop();
    expect(cache.isStopped, isTrue);
  });

  test('- prime worker with cache - perf', () async {
    final cache = CacheWorker();
    await cache.start();

    var cacheStats = await cache.getStats();
    expect(cacheStats.hit, isZero);
    expect(cacheStats.miss, isZero);
    expect(cacheStats.expired, isZero);
    expect(cacheStats.size, isZero);
    expect(cacheStats.maxSize, isZero);

    final primeWorker = PrimeWorker(cache);

    final sw = Stopwatch();
    sw.start();
    for (var prime in largePrimes) {
      expect(await primeWorker.isPrime(prime), isTrue);
    }
    final elapsedWithEmptyCache = sw.elapsedMicroseconds;

    cacheStats = await cache.getStats();
    expect(cacheStats.hit, isZero);
    expect(cacheStats.miss, isPositive);
    expect(cacheStats.expired, isZero);
    expect(cacheStats.size, isPositive);
    expect(cacheStats.maxSize, equals(cacheStats.size));

    sw.reset();
    for (var prime in largePrimes) {
      expect(await primeWorker.isPrime(prime), isTrue);
    }
    final elapsedWithFullCache = sw.elapsedMicroseconds;

    cacheStats = await cache.getStats();
    expect(cacheStats.hit, isPositive);
    expect(cacheStats.miss, isPositive);
    expect(cacheStats.hit, equals(cacheStats.miss));
    expect(cacheStats.expired, isZero);
    expect(cacheStats.size, isPositive);
    expect(cacheStats.maxSize, equals(cacheStats.size));

    expect(elapsedWithEmptyCache, greaterThan(10 * elapsedWithFullCache));

    primeWorker.stop();
    expect(primeWorker.isStopped, isTrue);

    cache.stop();
    expect(cache.isStopped, isTrue);
  });

  test('- exception handling from worker - Exception & WorkerException',
      () async {
    final rogue = RogueWorker();

    try {
      await rogue.throwException();
      // should never happen
      throw Exception('throwException() completed sucessfully');
    } catch (ex) {
      expect(ex, isA<WorkerException>());
      final wex = ex as WorkerException;
      expect(wex.message, contains('intentional exception'));
      expect(wex.stackTrace?.toString(), contains('throwException'));
      expect(wex.workerId, isNotNull);
    }
    expect(rogue.stats.totalErrors, equals(1));

    try {
      await rogue.throwWorkerException();
      // should never happen
      throw Exception('throwWorkerException() completed sucessfully');
    } catch (ex) {
      expect(ex, isA<WorkerException>());
      final wex = ex as WorkerException;
      expect(wex.message, equals('intentional worker exception'));
      expect(wex.stackTrace?.toString(), contains('throwWorkerException'));
      expect(wex.workerId, isNotNull);
    }
    expect(rogue.stats.totalErrors, equals(2));

    rogue.stop();
  });

  test('- exception handling from worker - TaskTimeOutException',
      () async {
    final testService = TestWorker();

    try {
      await testService.timeOut();
      // should never happen
      throw Exception('timeOut() completed sucessfully');
    } catch (ex) {
      expect(ex, isA<TaskTimeoutException>());
      final wex = ex as TaskTimeoutException;
      expect(wex.message, contains('intentional timeout exception'));
    }

    testService.stop();
  });

  test('- exception handling from worker - CancelledException',
      () async {
    final testService = TestWorker();

    try {
      await testService.cancelled();
      // should never happen
      throw Exception('cancel() completed sucessfully');
    } catch (ex) {
      expect(ex, isA<CancelledException>());
      final wex = ex as CancelledException;
      expect(wex.message, contains('intentional cancelled exception'));
    }

    testService.stop();
  });

  test('- exception handling from worker - CustomException', () async {
    SquadronException.registerExceptionDeserializer(
        CustomException.deserialize);
    final rogue = RogueWorker();

    try {
      await rogue.throwCustomException();
      // should never happen
      throw Exception('throwCustomException() completed successfully');
    } catch (e) {
      // expected exception
      expect(e, isA<CustomException>());
      final ex = e as CustomException;
      expect(ex.message, contains('intentional CUSTOM exception'));
      expect(ex.stackTrace?.toString(), contains('throwCustomException'));
      expect(ex.workerId, isNotNull);
      expect(ex.command, equals(RogueService.customExceptionCommand));
    }
    expect(rogue.stats.totalErrors, equals(1));

    rogue.stop();
  });

  test('- bitcoin service', () async {
    final bitcoin = BitcoinWorker();

    try {
      final eur = await bitcoin.getRate('EUR');
      expect(eur, isNotNull);
      expect(eur, isA<double>());
      expect(eur, isPositive);

      final gbp = await bitcoin.getRate('GBP');
      expect(gbp, isNotNull);
      expect(gbp, isA<double>());
      expect(gbp, isPositive);

      final usd = await bitcoin.getRate('USD');
      expect(usd, isNotNull);
      expect(usd, isA<double>());
      expect(usd, isPositive);

      expect(eur!, greaterThan(gbp!));
      expect(eur, lessThan(usd!));

      final rub = await bitcoin.getRate('RUB');
      expect(rub, isNull);
    } catch (ex) {
      expect(ex, isA<WorkerException>());
      final wex = ex as WorkerException;
      if (wex.message.contains('SocketException') ||
          wex.message.contains('XMLHttpRequest error')) {
        // on vm: WorkerException: SocketException: Failed host lookup: 'api.coindesk.com'
        // on browser: WorkerException: XMLHttpRequest error.
        // ignore this test
      } else {
        // otherwise something is broken, rethrow
        rethrow;
      }
    }

    bitcoin.stop();
  });

  group('- Streaming', () {
    test('- prime worker', () async {
      final primeWorker = PrimeWorker();
      // await primeWorker.start();

      final computedPrimes = await primeWorker.getPrimes(1, 1000).toList();

      expect(computedPrimes, equals(primesTo1000));

      primeWorker.stop();
      expect(primeWorker.isStopped, isTrue);
    });

    test('- with multiple errors - cancelOnError: false', () async {
      final testWorker = TestWorker();

      final token = CancellationToken('by request');

      final done = Completer();
      final numbers = <int>[];
      final errors = <SquadronException>[];

      testWorker.infiniteWithErrors(token).listen(
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
      final testWorker = TestWorker();

      final token = CancellationToken('by request');

      final numbers = <int>[];

      try {
        final future = testWorker
            .infiniteWithErrors(token)
            .listen(
              (number) => numbers.add(number),
              cancelOnError: true,
            )
            .asFuture();
        await Future.delayed(Duration.zero);
        final pending = await testWorker.getPendingInfiniteWithErrors();
        expect(pending, equals(1));
        await future;
        throw Exception('infiniteWithErrors() completed successfully');
      } catch (e) {
        expect(e, isA<WorkerException>());
        final ex = e as WorkerException;
        expect(ex.message, contains('error #'));
      }

      expect(numbers, equals([0, 1, 2]));

      final pending = await testWorker.getPendingInfiniteWithErrors();
      expect(pending, equals(0));
    });

    test('- with multiple errors - await for', () async {
      final testWorker = TestWorker();

      final token = CancellationToken('by request');

      final numbers = <int>[];

      try {
        await for (var number in testWorker.infiniteWithErrors(token)) {
          final pending = await testWorker.getPendingInfiniteWithErrors();
          expect(pending, equals(1));
          numbers.add(number);
        }
        throw Exception('infiniteWithErrors() completed successfully');
      } catch (e) {
        expect(e, isA<WorkerException>());
        final ex = e as WorkerException;
        expect(ex.message, contains('error #'));
      }

      expect(numbers, equals([0, 1, 2]));

      final pending = await testWorker.getPendingInfiniteWithErrors();
      expect(pending, equals(0));
    });

    test('- with multiple errors - throwing in await for', () async {
      final testWorker = TestWorker();

      final token = CancellationToken('by request');

      final numbers = <int>[];

      try {
        await for (var number in testWorker.infiniteWithErrors(token)) {
          final pending = await testWorker.getPendingInfiniteWithErrors();
          expect(pending, equals(1));
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

      final pending = await testWorker.getPendingInfiniteWithErrors();
      expect(pending, equals(0));
    });

    test('- with multiple errors - pause/resume', () async {
      final testWorker = TestWorker();

      final numbers = <int>[];
      final errors = <SquadronException>[];

      final token = CancellationToken('by request');
      final stream = testWorker.infiniteWithErrors(token);
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

    test('- with multiple errors - immediate cancellation', () async {
      final testWorker = TestWorker();

      final token = CancellationToken('by request');

      final numbers = <int>[];
      final errors = <SquadronException>[];

      final sub = testWorker.infiniteWithErrors(token).listen(
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

  test('- failing worker', () async {
    final failingWorker = FailingWorker();
    expect(() => failingWorker.start(), throwsA(isA<WorkerException>()));
  });

  test('- invalid worker', () async {
    final invalidWorker = InvalidWorker();
    expect(() => invalidWorker.start(), throwsA(isA<SquadronError>()));
  });

  test('- failing worker - missing command in Isolate implementation',
      () async {
    final failingWorker = FailingWorker.missingCommand();
    if (failingWorker != null) {
      expect(() => failingWorker.start(), throwsA(isA<SquadronError>()));
    }
  }, testOn: 'vm');

  test('- invalid request', () async {
    final rogue = RogueWorker();

    final transferable = [1];
    final result = await rogue.forward(transferable);
    expect(result, equals(transferable));

    try {
      final untransferable = getUntransferable();
      await rogue.forward(untransferable);
      // should never happen
      throw Exception(
          'forwarding an untransferable object completed successfully');
    } catch (ex) {
      expect(ex, isA<WorkerException>());
    } finally {
      // ensure worker is still alive
      final status = await rogue.ping();
      expect(status, isTrue);

      rogue.stop();
    }
  });

  test('- invalid response', () async {
    final rogue = RogueWorker();

    try {
      await rogue.invalidResponse();
      // should never happen
      throw Exception('invalidResponse() completed successfully');
    } catch (ex) {
      expect(ex, isA<WorkerException>());
    } finally {
      // ensure worker is still alive
      final status = await rogue.ping();
      expect(status, isTrue);

      rogue.stop();
    }
  });

  test('- missing operation', () async {
    final rogue = RogueWorker();

    try {
      await rogue.missingOperation();
      // should never happen
      throw Exception('missingOperation() completed successfully');
    } catch (ex) {
      expect(ex, isA<WorkerException>());
    }

    // ensure worker is still alive
    final status = await rogue.ping();
    expect(status, isTrue);
    rogue.stop();
  });
}
