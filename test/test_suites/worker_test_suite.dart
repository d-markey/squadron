import 'dart:async';

import 'package:squadron/squadron.dart';
import 'package:squadron/src/squadron.dart';
import 'package:test/test.dart';

import '../classes/custom_exception.dart';
import '../classes/memory_logger.dart';
import '../classes/prime_numbers.dart';
import '../classes/platform.dart';
import '../worker_services/cache_service_worker.dart';
import '../worker_services/prime_service_worker.dart';
import '../worker_services/test_service.dart';
import '../worker_services/test_service_worker.dart';
import '../worker_services/worker_entry_points.dart';

void workerTests() {
  group('- start/stop', () {
    dynamic initialLogger;
    final memoryLogger = MemoryLogger();

    setUp(() {
      initialLogger = getSquadronLogger();
      memoryLogger.clear();
      Squadron.pushLogLevel(SquadronLogLevel.all);
      Squadron.setLogger(memoryLogger);
      Squadron.debugMode = false;
    });

    tearDown(() {
      Squadron.setLogger(initialLogger);
      Squadron.popLogLevel();
      Squadron.debugMode = false;
    });

    test('- start & stop', () async {
      final worker = TestWorker();

      await Future.delayed(TestService.shortDelay);
      expect(worker.channel, isNull);
      expect(worker.upTime, Duration.zero);
      expect(worker.idleTime, Duration.zero);
      expect(worker.isStopped, isFalse);

      final channel = await worker.start();
      expect(worker.channel, isNotNull);
      expect(channel, equals(worker.channel));

      await Future.delayed(TestService.shortDelay);
      expect(worker.upTime, greaterThan(Duration.zero));
      expect(worker.isStopped, false);

      var upTime = worker.upTime;
      expect(upTime, greaterThan(Duration.zero));
      expect(worker.idleTime, greaterThanOrEqualTo(upTime));

      worker.stop();
      expect(worker.isStopped, isTrue);

      upTime = worker.upTime;
      expect(worker.channel, isNull);
      expect(worker.upTime, greaterThan(Duration.zero));

      await Future.delayed(TestService.shortDelay);

      expect(worker.upTime, equals(upTime));
      expect(worker.idleTime, greaterThan(worker.upTime));
    });

    test('- hook', () async {
      String? platformTypeName;

      void hook(PlatformWorker pw) {
        platformTypeName = pw.runtimeType.toString();
      }

      final worker = TestWorker(hook);

      await Future.delayed(TestService.shortDelay);
      expect(platformTypeName, isNull);

      await worker.start();
      expect(platformTypeName,
          equals(EntryPoints.platform == 'WEB' ? 'Worker' : 'Isolate'));

      worker.stop();

      await Future.delayed(TestService.shortDelay);
    });

    test('- hook failure', () async {
      String? platformTypeName;

      void hook(PlatformWorker pw) {
        platformTypeName = pw.runtimeType.toString();
        throw Exception('intended exception for $platformTypeName');
      }

      final worker = TestWorker(hook);

      await Future.delayed(TestService.shortDelay);
      expect(platformTypeName, isNull);

      await worker.start();
      expect(platformTypeName,
          equals(EntryPoints.platform == 'WEB' ? 'Worker' : 'Isolate'));
      expect(memoryLogger.contains('intended exception'), isTrue);

      worker.stop();

      await Future.delayed(TestService.shortDelay);
    });

    test('- cannot restart after stop', () async {
      final worker = TestWorker();
      await worker.start();

      await Future.delayed(TestService.shortDelay);
      worker.stop();
      expect(worker.isStopped, isTrue);
      await Future.delayed(TestService.shortDelay);

      try {
        await worker.start();
        // should never happen
        throw Exception('stopped channel restarted successfully');
      } catch (ex) {
        expect(ex, isA<WorkerException>());
      }
    });
  });

  group('- workloads', () {
    test('- sequential', () async {
      final worker = TestWorker();
      await worker.start();

      final completedTasks = <int>[];
      int taskId = 0;

      Future createTask(Duration duration) {
        final id = ++taskId;
        return worker
            .io(ms: duration.inMilliseconds)
            .whenComplete(() => completedTasks.add(id));
      }

      expect(completedTasks, isEmpty);
      expect(worker.workload, isZero);
      expect(worker.maxWorkload, isZero);
      expect(worker.totalWorkload, isZero);

      await createTask(TestService.shortDelay); // task 1

      expect(completedTasks, equals([1]));
      expect(worker.workload, isZero);
      expect(worker.maxWorkload, equals(1));
      expect(worker.totalWorkload, equals(1));

      var task = createTask(TestService.shortDelay * 2); // task 2

      expect(completedTasks, equals([1]));
      expect(worker.workload, equals(1));
      expect(worker.maxWorkload, equals(1));
      expect(worker.totalWorkload, equals(1));

      await Future.delayed(TestService.shortDelay);

      expect(completedTasks, equals([1]));
      expect(worker.workload, equals(1));
      expect(worker.maxWorkload, equals(1));
      expect(worker.totalWorkload, equals(1));

      await task;

      expect(completedTasks, equals([1, 2]));
      expect(worker.workload, isZero);
      expect(worker.maxWorkload, equals(1));
      expect(worker.totalWorkload, equals(2));

      await createTask(TestService.shortDelay); // task 3

      expect(completedTasks, equals([1, 2, 3]));
      expect(worker.workload, isZero);
      expect(worker.maxWorkload, equals(1));
      expect(worker.totalWorkload, equals(3));

      worker.stop();

      expect(worker.workload, isZero);
      expect(worker.maxWorkload, equals(1));
      expect(worker.totalWorkload, equals(3));
    });

    test('- parallel', () async {
      final worker = TestWorker();
      await worker.start();

      final completedTasks = <int>[];
      int taskId = 0;

      Future createTask(Duration duration) {
        final id = ++taskId;
        return worker
            .io(ms: duration.inMilliseconds)
            .whenComplete(() => completedTasks.add(id));
      }

      await worker.start();

      expect(completedTasks, isEmpty);
      expect(worker.workload, isZero);
      expect(worker.maxWorkload, isZero);
      expect(worker.totalWorkload, isZero);

      var tasks = [
        createTask(TestService.delay), // task 1
        createTask(TestService.delay * 2), // task 2
        createTask(TestService.delay * 1.5), // task 3
      ];

      expect(completedTasks, isEmpty);
      expect(worker.workload, equals(3));
      expect(worker.maxWorkload, equals(3));
      expect(worker.totalWorkload, isZero);

      await Future.wait(tasks);

      expect(completedTasks, equals([1, 3, 2]));
      expect(worker.workload, isZero);
      expect(worker.maxWorkload, equals(3));
      expect(worker.totalWorkload, equals(3));

      completedTasks.clear();

      /////////// time origin for next tasks ///////////

      createTask(TestService.delay * 7); // #4 complete at 7 delays
      createTask(TestService.delay * 5); // #5 complete at 5 delays
      createTask(TestService.delay * 3); // #6 complete at 3 delays

      expect(completedTasks, isEmpty);
      expect(worker.workload, equals(3));
      expect(worker.maxWorkload, equals(3));
      expect(worker.totalWorkload, equals(3));

      await Future.delayed(
          TestService.delay * 1.5); // 1.5 delay: all tasks still pending

      expect(completedTasks, isEmpty);
      expect(worker.workload, equals(3));
      expect(worker.maxWorkload, equals(3));
      expect(worker.totalWorkload, equals(3));

      await Future.delayed(TestService.delay *
          4); // 5.5 delays: tasks #6 & #5 finished, #4 still pending

      expect(completedTasks, equals([6, 5]));
      expect(worker.workload, equals(1));
      expect(worker.maxWorkload, equals(3));
      expect(worker.totalWorkload, equals(5));

      createTask(TestService.delay * 5); // #7 complete at 10.5 delays
      createTask(TestService.delay * 3); // #8 complete at 8.5 delays

      expect(completedTasks, equals([6, 5]));
      expect(worker.workload, equals(3));
      expect(worker.maxWorkload, equals(3));
      expect(worker.totalWorkload, equals(5));

      await Future.delayed(TestService.delay *
          4); // 9.5 delays: tasks #4 and #8 complete, #7 still pending

      expect(completedTasks, equals([6, 5, 4, 8]));
      expect(worker.workload, equals(1));
      expect(worker.maxWorkload, equals(3));
      expect(worker.totalWorkload, equals(7));

      await Future.delayed(
          TestService.delay * 2.5); // 12 delays: all tasks finished

      expect(completedTasks, equals([6, 5, 4, 8, 7]));
      expect(worker.workload, isZero);
      expect(worker.maxWorkload, equals(3));
      expect(worker.totalWorkload, equals(8));

      worker.stop();
      expect(worker.workload, isZero);
      expect(worker.maxWorkload, equals(3));
      expect(worker.totalWorkload, equals(8));
    });
  });

  group('- initialization error', () {
    test('- failed init', () async {
      final worker = TestWorker.failedInit();
      try {
        await worker.start();
        throw Exception('start() returned successfully');
      } catch (ex) {
        expect(ex, isA<WorkerException>());
      }

      try {
        await worker.ping();
        throw Exception('ping() returned successfully');
      } catch (ex) {
        expect(ex, isA<WorkerException>());
      }
    });

    test('- missing start request', () async {
      final worker = TestWorker.missingStartRequest();
      if (worker != null) {
        try {
          await worker.start();
          throw Exception('start() returned successfully');
        } catch (ex) {
          expect(ex, isA<SquadronError>());
        }

        try {
          await worker.ping();
          throw Exception('ping() returned successfully');
        } catch (ex) {
          expect(ex, isA<SquadronError>());
        }
      }
    });

    test('- invalid command ID', () async {
      Squadron.logLevel = SquadronLogLevel.all;
      final worker = TestWorker.invalidCommand();
      try {
        await worker.start();
        throw Exception('start() returned successfully');
      } catch (ex) {
        expect(ex, isA<SquadronError>());
      }

      try {
        await worker.ping();
        throw Exception('ping() returned successfully');
      } catch (ex) {
        expect(ex, isA<SquadronError>());
      }
    });
  });

  group('- error handling', () {
    late final TestWorker worker;

    setUpAll(() {
      worker = TestWorker();
      return worker.start();
    });

    test('- Exception', () async {
      final errors = worker.stats.totalErrors;
      try {
        await worker.throwException();
        // should never happen
        throw Exception('throwException() completed sucessfully');
      } catch (ex) {
        expect(ex, isA<WorkerException>());
        final wex = ex as WorkerException;
        expect(wex.message, contains('intentional exception'));
        expect(wex.stackTrace?.toString(), contains('throwException'));
        expect(wex.workerId, isNotNull);
      }
      expect(worker.stats.totalErrors, equals(errors + 1));
    });

    test('- WorkerException', () async {
      final errors = worker.stats.totalErrors;
      try {
        await worker.throwWorkerException();
        // should never happen
        throw Exception('throwWorkerException() completed sucessfully');
      } catch (ex) {
        expect(ex, isA<WorkerException>());
        final wex = ex as WorkerException;
        expect(wex.message, equals('intentional worker exception'));
        expect(wex.stackTrace?.toString(), contains('throwWorkerException'));
        expect(wex.workerId, isNotNull);
      }
      expect(worker.stats.totalErrors, equals(errors + 1));
    });

    test('- TaskTimeOutException', () async {
      final errors = worker.stats.totalErrors;
      try {
        await worker.throwTaskTimeOutException();
        // should never happen
        throw Exception('throwTaskTimeOutException() completed sucessfully');
      } catch (ex) {
        expect(ex, isA<TaskTimeoutException>());
        final wex = ex as TaskTimeoutException;
        expect(wex.message, contains('intentional timeout exception'));
      }
      expect(worker.stats.totalErrors, equals(errors + 1));
    });

    test('- CancelledException', () async {
      final errors = worker.stats.totalErrors;
      try {
        await worker.throwCancelledException();
        // should never happen
        throw Exception('throwCancelledException() completed sucessfully');
      } catch (ex) {
        expect(ex, isA<CancelledException>());
        final wex = ex as CancelledException;
        expect(wex.message, contains('intentional cancelled exception'));
      }
      expect(worker.stats.totalErrors, equals(errors + 1));
    });

    test('- CustomException', () async {
      SquadronException.registerExceptionDeserializer(
          CustomException.deserialize);

      final errors = worker.stats.totalErrors;
      try {
        await worker.throwCustomException();
        // should never happen
        throw Exception('throwCustomException() completed successfully');
      } catch (e) {
        // expected exception
        expect(e, isA<CustomException>());
        final ex = e as CustomException;
        expect(ex.message, contains('intentional CUSTOM exception'));
        expect(ex.stackTrace?.toString(), contains('throwCustomException'));
        expect(ex.workerId, isNotNull);
        expect(ex.command, equals(TestService.throwCustomExceptionCommand));
      }
      expect(worker.stats.totalErrors, equals(errors + 1));
    });

    test('- invalid request', () async {
      final transferable = [1];
      final result = await worker.forward(transferable);
      expect(result, equals(transferable));

      try {
        final untransferable = getUntransferable();
        await worker.forward(untransferable);
        // should never happen
        throw Exception('forward(untransferable) completed successfully');
      } catch (ex) {
        expect(ex, isA<WorkerException>());
      }
      // ensure worker is still alive
      final status = await worker.ping();
      expect(status, isTrue);
    });

    test('- invalid response', () async {
      try {
        await worker.invalidResponse();
        // should never happen
        throw Exception('invalidResponse() completed successfully');
      } catch (ex) {
        expect(ex, isA<WorkerException>());
      }
      // ensure worker is still alive
      final status = await worker.ping();
      expect(status, isTrue);
    });

    test('- missing operation', () async {
      try {
        await worker.missing();
        // should never happen
        throw Exception('missingOperation() completed successfully');
      } catch (ex) {
        expect(ex, isA<WorkerException>());
      }
      // ensure worker is still alive
      final status = await worker.ping();
      expect(status, isTrue);
    });

    tearDownAll(() {
      worker.stop();
    });
  });

  group('- streaming', () {
    late TestWorker worker;

    setUpAll(() {
      worker = TestWorker();
      return worker.start();
    });

    tearDownAll(() {
      worker.stop();
    });

    test('- cancelOnError: false', () async {
      final done = Completer();
      final numbers = <int>[];
      final errors = <SquadronException>[];
      final maxErrors = 3;

      var pending = await worker.getPendingInfiniteWithErrors();
      expect(pending, isZero);

      late StreamSubscription sub;
      sub = worker.infiniteWithErrors().listen(
            (number) => numbers.add(number),
            onError: (ex) {
              errors.add(ex);
              if (errors.length >= maxErrors) {
                sub.cancel();
                done.complete();
              }
            },
            onDone: () => done.complete(),
            cancelOnError: false,
          );

      pending = await worker.getPendingInfiniteWithErrors();
      expect(pending, equals(1));

      await done.future;

      expect(errors.length, equals(maxErrors));
      expect(numbers.length, greaterThan(errors.length));
      expect(errors.every((e) => e.message.contains('error #')), isTrue);

      pending = await worker.getPendingInfiniteWithErrors();
      expect(pending, isZero);
    });

    test('- cancelOnError: true', () async {
      final numbers = <int>[];

      var pending = await worker.getPendingInfiniteWithErrors();
      expect(pending, isZero);

      try {
        final done = worker
            .infiniteWithErrors()
            .listen(
              (number) => numbers.add(number),
              cancelOnError: true,
            )
            .asFuture();

        pending = await worker.getPendingInfiniteWithErrors();
        expect(pending, equals(1));

        await done;

        throw Exception('infiniteWithErrors() completed successfully');
      } catch (e) {
        expect(e, isA<WorkerException>());
        final ex = e as WorkerException;
        expect(ex.message, contains('error #'));
      }

      expect(numbers, equals([0, 1, 2]));

      pending = await worker.getPendingInfiniteWithErrors();
      expect(pending, isZero);
    });

    test('- await for', () async {
      final numbers = <int>[];

      try {
        await for (var number in worker.infiniteWithErrors()) {
          final pending = await worker.getPendingInfiniteWithErrors();
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

      final pending = await worker.getPendingInfiniteWithErrors();
      expect(pending, isZero);
    });

    test('- throwing in await for', () async {
      final numbers = <int>[];

      try {
        await for (var number in worker.infiniteWithErrors()) {
          final pending = await worker.getPendingInfiniteWithErrors();
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

      final pending = await worker.getPendingInfiniteWithErrors();
      expect(pending, isZero);
    });

    test('- pause/resume', () async {
      var pending = await worker.getPendingInfiniteWithErrors();
      expect(pending, isZero);

      final numbers = <int>[];
      final errors = <SquadronException>[];

      final sub = worker.infiniteWithErrors().listen(
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

      await Future.delayed(TestService.delay);

      pending = await worker.getPendingInfiniteWithErrors();
      expect(pending, isZero);
    });

    test('- immediate cancellation', () async {
      var pending = await worker.getPendingInfiniteWithErrors();
      expect(pending, isZero);

      final numbers = <int>[];
      final errors = <SquadronException>[];

      final sub = worker.infiniteWithErrors().listen(
            (number) => numbers.add(number),
            onError: (ex) => errors.add(ex),
            cancelOnError: false,
          );

      sub.cancel();

      await Future.delayed(TestService.delay * 3);

      expect(numbers, isEmpty);
      expect(errors, isEmpty);

      pending = await worker.getPendingInfiniteWithErrors();
      expect(pending, isZero);
    });
  });

  group('- sharing wokers', () {
    test('- cache worker', () async {
      final cache = CacheWorker();

      expect(await cache.get(1), isNull);
      expect(await cache.containsKey(1), isFalse);
      await cache.set(1, 'in cache');
      expect(await cache.containsKey(1), isTrue);
      expect(await cache.get(1), equals('in cache'));

      cache.stop();
      expect(cache.isStopped, isTrue);
    });

    test('- prime worker with cache', () async {
      final cache = CacheWorker();
      await cache.start();

      var cacheStats = await cache.getStats();
      expect(cacheStats.hit, isZero);
      expect(cacheStats.miss, isZero);
      expect(cacheStats.expired, isZero);
      expect(cacheStats.size, isZero);
      expect(cacheStats.maxSize, isZero);

      final primeWorker = PrimeWorker(cache);

      final sw = Stopwatch()..start();
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

      expect(elapsedWithFullCache, lessThan(elapsedWithEmptyCache / 5));

      primeWorker.stop();
      expect(primeWorker.isStopped, isTrue);

      cache.stop();
      expect(cache.isStopped, isTrue);
    });
  });
}
