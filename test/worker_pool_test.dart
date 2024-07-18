@TestOn('vm || browser')
library;

import 'dart:async';

import 'package:cancelation_token/cancelation_token.dart';
import 'package:logger/logger.dart';
import 'package:squadron/squadron.dart';
import 'package:test/test.dart';
import 'package:using/using.dart';

import 'classes/custom_exception.dart';
import 'classes/prime_numbers.dart';
import 'classes/test_context.dart';
import 'classes/utils.dart';
import 'worker_services/cache_service_worker.dart';
import 'worker_services/delays.dart';
import 'worker_services/prime_service_worker.dart';
import 'worker_services/test_service_worker.dart';

const concurrencySettings_222 =
    ConcurrencySettings(minWorkers: 2, maxWorkers: 2, maxParallel: 2);

void main() async {
  final testContext = await TestContext.init('');
  execute(testContext);
}

String testScript = 'worker_pool_test.dart';

void execute(TestContext tc) {
  tc.run(() {
    final logger = Logger(level: Level.all);

    tc.group("- WorkerPool", () {
      tc.test('- prime worker pool with cache', () async {
        await CacheWorker(
          tc,
        ).useAsync((cache) async {
          await cache.start();
          await PrimeWorkerPool(
            tc,
            cache,
            concurrencySettings_222,
          ).useAsync((pool) async {
            await pool.start();

            final completedTasks = <int>[];
            int taskId = 0;

            const loops = 1;

            final tasks = <Future>[];
            for (var i = 1; i <= loops * pool.maxConcurrency; i++) {
              var id = ++taskId;
              tasks.add(
                  pool.isPrime(i).whenComplete(() => completedTasks.add(id)));
            }

            await Future.wait(tasks);

            expect(completedTasks.length, equals(tasks.length));

            final stats = pool.stats.toList();
            expect(stats.length, equals(pool.maxWorkers));
            expect(
                stats.every((s) => s.maxWorkload <= pool.maxParallel), isTrue);
          });
        });
      });

      tc.test('- worker pool monitoring', () async {
        await TestWorkerPool(
          tc,
          ConcurrencySettings(minWorkers: 2, maxWorkers: 5, maxParallel: 3),
        ).useAsync((pool) async {
          var stopped = 0;

          // start pool will instantiate minWorkers workers
          await pool.start();
          expect(pool.size, equals(pool.minWorkers));

          final maxIdle = TestDelays.delay;

          final tasks = <Future>[];
          for (var i = 0; i < 2 * pool.maxConcurrency + 1; i++) {
            tasks.add(pool.io(ms: TestDelays.delay.inMilliseconds * 10));
          }

          // let the pool kick off some tasks
          await Future.delayed(maxIdle * 3);

          // the pool should be running at full speed
          expect(pool.size, equals(pool.maxWorkers));
          expect(stopped, isZero);

          // install the worker monitor
          final timer = Timer.periodic(maxIdle * 0.5, (timer) {
            stopped += pool.stop((w) => w.idleTime > maxIdle);
          });

          // let tasks continue their work for a short while
          await Future.delayed(maxIdle * 2);

          // while there is pending work, no worker should be stopped
          expect(stopped, isZero);

          // wait until completion
          await Future.wait(tasks);

          // go idle
          await Future.delayed(maxIdle * 3);

          // the extra workers should have been stopped
          expect(stopped, isPositive);

          // the pool should be back to minimum size
          expect(pool.size, equals(pool.minWorkers));

          timer.cancel();
        });
      });

      tc.group('- initialization error', () {
        tc.test('- failed init', () async {
          await TestWorkerPool.throws(
            tc,
          ).useAsync((pool) async {
            try {
              await pool.start();
              throw unexpectedSuccess('start()');
            } on SquadronError catch (_) {
              // expected exception
            }

            try {
              final res = await pool.ping();
              throw unexpectedSuccess('ping()', res);
            } on CanceledException catch (_) {
              // expected exception
            }

            expect(pool.size, isZero);
          });
        });

        tc.test(
            '- missing command',
            () => TestWorkerPool.missingStartRequest(tc).useAsync((pool) async {
                  try {
                    await pool.start();
                    throw unexpectedSuccess('start()');
                  } on SquadronError {
                    // expected exception
                  }

                  try {
                    final res = await pool.ping();
                    throw unexpectedSuccess('ping()', res);
                  } on CanceledException {
                    // expected exception
                  }

                  expect(pool.size, isZero);
                }),
            skip: tc.entryPoints.missingStartRequest == null);

        tc.test('- invalid command ID', () async {
          await TestWorkerPool.invalid(
            tc,
          ).useAsync((pool) async {
            try {
              await pool.start();
              throw unexpectedSuccess('start()');
            } on SquadronError catch (_) {
              // expected exception
            }

            try {
              final res = await pool.ping();
              throw unexpectedSuccess('ping()', res);
            } on CanceledException catch (_) {
              // expected exception
            }

            expect(pool.size, isZero);
          });
        });
      });

      tc.group('- error handling', () {
        tc.test('- Exception', () async {
          await TestWorkerPool(
            tc,
            concurrencySettings_222,
          ).useAsync((pool) async {
            await pool.start();

            try {
              final res = await pool.execute((w) => w.throwException());
              throw unexpectedSuccess('throwException()', res);
            } on WorkerException catch (ex) {
              lowerCaseCheck(ex.message, contains('intentional exception'));
              caseCheck(ex.stackTrace, contains('throwException'));
            }
            expect(pool.stats.fold<int>(0, (p, s) => p + s.totalErrors),
                equals(1));
          });
        });

        tc.test('- WorkerException', () async {
          await TestWorkerPool(
            tc,
            concurrencySettings_222,
          ).useAsync((pool) async {
            await pool.start();

            try {
              final res = await pool.execute((w) => w.throwWorkerException());
              throw unexpectedSuccess('throwWorkerException()', res);
            } on WorkerException catch (ex) {
              lowerCaseCheck(
                  ex.message, contains('intentional worker exception'));
              caseCheck(ex.stackTrace, contains('throwWorkerException'));
            }
            expect(pool.stats.fold<int>(0, (p, s) => p + s.totalErrors),
                equals(1));
          });
        });

        tc.test('- TaskTimeOutException', () async {
          await TestWorkerPool(
            tc,
          ).useAsync((pool) async {
            await pool.start();

            try {
              final res = await pool.throwTaskTimeOutException();
              throw unexpectedSuccess('timeOut()', res);
            } on TimeoutException catch (ex) {
              lowerCaseCheck(
                  ex.message, contains('intentional timeout exception'));
            }
          });
        });

        tc.test('- CanceledException', () async {
          await TestWorkerPool(
            tc,
          ).useAsync((pool) async {
            try {
              final res = await pool.throwCanceledException();
              throw unexpectedSuccess('cancel()', res);
            } on CanceledException catch (ex) {
              lowerCaseCheck(
                  ex.message, contains('intentional canceled exception'));
            }
          });
        });

        tc.test('- CustomException', () async {
          await TestWorkerPool(
            tc,
          ).useAsync((pool) async {
            pool.exceptionManager
                .register(CustomException.typeId, CustomException.deserialize);

            try {
              final res = await pool.throwCustomException();
              throw unexpectedSuccess('cancel()', res);
            } on CustomException catch (ex) {
              lowerCaseCheck(
                  ex.message, contains('intentional custom exception'));
            }
          });
        });

        tc.test('- CustomException - after deserializer deregistation',
            () async {
          await TestWorkerPool(
            tc,
          ).useAsync((pool) async {
            pool.exceptionManager
                .register(CustomException.typeId, CustomException.deserialize);

            try {
              final res = await pool.throwCustomException();
              throw unexpectedSuccess('cancel()', res);
            } on CustomException catch (ex) {
              lowerCaseCheck(
                  ex.message, contains('intentional custom exception'));
            }

            pool.exceptionManager.unregister(CustomException.typeId);

            try {
              final res = await pool.throwCustomException();
              throw unexpectedSuccess('cancel()', res);
            } on SquadronException catch (ex) {
              expect(ex, isNot(isA<CustomException>()));
              lowerCaseCheck(
                  ex.message, contains('intentional custom exception'));
            }
          });
        });
      });

      tc.test('- value - performance', () async {
        await PrimeWorkerPool(
          tc,
        ).useAsync((pool) async {
          final counter = PerfCounter('perf');
          final tasks = <Future>[];
          for (var i = 0; i < 3 * pool.maxConcurrency + 1; i++) {
            tasks.add(pool.isPrime(largePrimes.last, counter));
          }

          final start = counter.snapshot;
          expect(start.totalCount, isZero);
          expect(start.totalErrors, isZero);
          expect(start.totalTimeInMicroseconds, isZero);

          await tasks[0];

          final progress = counter.snapshot;
          expect(progress.totalCount, isPositive);
          expect(progress.totalErrors, isZero);
          expect(progress.totalTimeInMicroseconds, isPositive);

          await Future.wait(tasks);

          final end = counter.snapshot;
          logger.t(
              'end: ${end.totalCount} / ${end.totalErrors} / ${end.totalTimeInMicroseconds}');
          expect(end.totalCount, greaterThan(progress.totalCount));
          expect(end.totalErrors, isZero);
          expect(end.totalTimeInMicroseconds,
              greaterThan(progress.totalTimeInMicroseconds));
        });
      });

      tc.test('- streaming - performance', () async {
        await PrimeWorkerPool(
          tc,
        ).useAsync((pool) async {
          // start N tasks and measure performance
          final counter = PerfCounter('perf');
          final tasks = <Future>[];
          for (var i = 0; i < 3 * pool.maxConcurrency + 1; i++) {
            tasks.add(pool.getPrimes(0, 1000, counter).drain());
          }

          final start = counter.snapshot;
          expect(start.totalCount, isZero);
          expect(start.totalErrors, isZero);
          expect(start.totalTimeInMicroseconds, isZero);

          await tasks[0];

          final progress = counter.snapshot;
          expect(progress.totalCount, isPositive);
          expect(progress.totalErrors, isZero);
          expect(progress.totalTimeInMicroseconds, isPositive);

          await Future.wait(tasks);

          final end = counter.snapshot;
          expect(end.totalCount, greaterThan(progress.totalCount));
          expect(end.totalErrors, isZero);
          expect(end.totalTimeInMicroseconds,
              greaterThan(progress.totalTimeInMicroseconds));
        });
      });

      tc.test('- stopped pool will not accept new requests', () async {
        await TestWorkerPool(
          tc,
          ConcurrencySettings.oneIoThread,
        ).useAsync((pool) async {
          final n = await pool.delayed(-1);
          expect(n, equals(-1));

          pool.stop();

          try {
            final n = await pool.delayed(-1);
            throw unexpectedSuccess('delayed()', n);
          } on SquadronError catch (ex) {
            lowerCaseCheck(ex.message, contains('cannot accept new requests'));
            lowerCaseCheck(ex.message, contains('stopped'));
          }
        });
      });

      tc.test('- restarted pool will serve new requests', () async {
        await TestWorkerPool(
          tc,
          ConcurrencySettings.twoIoThreads,
        ).useAsync((pool) async {
          await pool.start();

          expect(pool.size, isPositive);

          var n = await pool.delayed(-1);
          expect(n, equals(-1));

          pool.stop();

          expect(pool.size, isZero);
          expect(pool.stopped, isTrue);

          try {
            n = await pool.delayed(-1);
            throw unexpectedSuccess('delayed()', n);
          } on SquadronError catch (ex) {
            lowerCaseCheck(ex.message, contains('cannot accept new requests'));
            lowerCaseCheck(ex.message, contains('stopped'));
          }

          // restart
          pool.start(); // intentionally not awaited

          n = await pool.delayed(-2);
          expect(n, equals(-2));
        });
      });

      tc.test('- pool termination does not prevent processing of pending tasks',
          () async {
        await TestWorkerPool(
          tc,
          ConcurrencySettings.threeCpuThreads,
        ).useAsync((pool) async {
          final N = 2 * pool.maxConcurrency + pool.maxWorkers;

          final digits = <int>[];
          final tasks = <Future>[];
          for (var i = 0; i < N; i++) {
            tasks.add(pool.delayed(i).then((value) {
              digits.add(value);
            }));
          }

          await Future.delayed(TestDelays.delay);
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
      });

      tc.group('- Streaming', () {
        tc.test('- with multiple errors - cancelOnError: false', () async {
          await TestWorkerPool(
            tc,
          ).useAsync((pool) async {
            final token = CancelableToken();

            final done = Completer();
            final numbers = <int>[];
            final errors = <SquadronException>[];

            pool.infiniteWithErrors(token).listen(
              numbers.add,
              onError: (ex) {
                errors.add(ex);
                if (errors.length > 3) {
                  token.cancel(CanceledException('by request'));
                }
              },
              onDone: done.complete,
              cancelOnError: false,
            );

            await done.future;

            expect(numbers.length, greaterThan(3 * 2));
            expect(errors.length, greaterThan(3));
            final lowerCaseMessages =
                errors.map((e) => e.message.toLowerCase());
            expect(lowerCaseMessages.where((m) => m.contains('error #')).length,
                greaterThan(3));
            expect(
                lowerCaseMessages.where((m) => m.contains('by request')).length,
                equals(1));
          });
        });

        tc.test('- with multiple errors - cancelOnError: true', () async {
          final testWorkerPool = TestWorkerPool(tc);

          final token = CancelableToken();

          final numbers = <int>[];

          try {
            final res = await testWorkerPool
                .infiniteWithErrors(token)
                .listen(
                  (number) => numbers.add(number),
                  cancelOnError: true,
                )
                .asFuture();
            throw unexpectedSuccess('infiniteWithErrors()', res);
          } on WorkerException catch (ex) {
            lowerCaseCheck(ex.message, contains('error #'));
          }

          expect(numbers, equals([0, 1, 2]));
        });

        tc.test('- with multiple errors - await for', () async {
          final testWorkerPool = TestWorkerPool(tc);

          final token = CancelableToken();

          final numbers = <int>[];

          try {
            await for (var number in testWorkerPool.infiniteWithErrors(token)) {
              numbers.add(number);
            }
            throw unexpectedSuccess('infiniteWithErrors()', null);
          } on WorkerException catch (e) {
            lowerCaseCheck(e.message, contains('error #'));
          }

          expect(numbers, equals([0, 1, 2]));
        });

        tc.test('- with multiple errors - throwing in await for', () async {
          final testWorkerPool = TestWorkerPool(tc);

          final token = CancelableToken();

          final numbers = <int>[];

          try {
            await for (var number in testWorkerPool.infiniteWithErrors(token)) {
              if (numbers.isEmpty) {
                numbers.add(number);
              } else {
                throw WorkerException('Client-side exception');
              }
            }
            throw unexpectedSuccess('infiniteWithErrors()', null);
          } on WorkerException catch (e) {
            expect(e.message, equals('Client-side exception'));
          }

          expect(numbers, equals([0]));
        });

        tc.test('- with multiple errors - pause/resume', () async {
          final testWorkerPool = TestWorkerPool(tc);

          final numbers = <int>[];
          final errors = <SquadronException>[];

          final token = CancelableToken();
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
          await Future.delayed(TestDelays.delay * 4);
          expect(numbers, isEmpty);
          expect(errors, isEmpty);
          // resume
          sub.resume();

          await Future.delayed(TestDelays.delay * 4);
          pause();
          pause();
          await Future.delayed(TestDelays.delay * 4);
          resume();
          await Future.delayed(TestDelays.delay * 4);
          resume();
          await Future.delayed(TestDelays.delay * 4);

          sub.cancel();

          expect(numbers.length, greaterThan(countNumbers));
          expect(errors.length, greaterThan(countErrors));
          expect(errors.map((e) => e.message), doesNotMention('by request'));
        });

        tc.test(
            '- with multiple errors - pause/resume/cancel - using a StreamTask',
            () async {
          // at most one task
          final pool = TestWorkerPool(tc, ConcurrencySettings.oneCpuThread);
          expect(pool.maxConcurrency, equals(1));
          await pool.start();

          final numbers0 = <int>[];
          final errors0 = <SquadronException>[];
          final token0 = CancelableToken();
          final task0 = pool.infiniteWithErrorsTask(token0);
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
          final token1 = CancelableToken();
          final task1 = pool.infiniteWithErrorsTask(token1);
          final stream1 = task1.stream;
          final sub1 = stream1.listen(
            (number) => numbers1.add(number),
            onError: (ex) => errors1.add(ex),
            cancelOnError: false,
          );

          sub0.pause();
          sub1.pause();

          await Future.delayed(TestDelays.shortDelay * 3);

          expect(numbers0, isEmpty);
          expect(errors0, isEmpty);
          expect(numbers1, isEmpty);
          expect(errors1, isEmpty);

          sub0.resume();
          sub1.resume();

          await Future.delayed(TestDelays.shortDelay * 3);

          expect(numbers0, isNotEmpty);
          expect(errors0, isNotEmpty);
          expect(numbers1, isEmpty);
          expect(errors1, isEmpty);

          // pause second stream, cancel first stream task
          sub1.pause();
          token0.cancel(CanceledException('by token #0'));

          final numbersCount0 = numbers0.length;
          final errorsCount0 = errors0.length;

          expect(numbers1, isEmpty);
          expect(errors1, isEmpty);

          // the second stream should be buffering events
          await Future.delayed(TestDelays.shortDelay * 3);

          expect(numbers0.length, numbersCount0);
          expect(errors0.length, errorsCount0 + 1);
          expect(errors0.last.message, equals('by token #0'));
          expect(numbers1, isEmpty);
          expect(errors1, isEmpty);

          // resume: buffered event should be processed
          sub1.resume();
          await Future.delayed(TestDelays.shortDelay * 3);

          expect(numbers0.length, numbersCount0);
          expect(errors0.length, errorsCount0 + 1);
          expect(numbers1, isNotEmpty);
          expect(errors1, isNotEmpty);

          // terminate
          sub1.cancel();
          sub0.cancel();

          await Future.delayed(TestDelays.delay);

          // /!\ cannot call getPendingInfiniteWithErrors() while task0 & task1 are still pending!
          final pending = await pool.getPendingInfiniteWithErrors();
          expect(pending, isZero);
        });

        tc.test('- with multiple errors - immediate cancelation', () async {
          final pool = TestWorkerPool(tc);
          await pool.start();

          final token = CancelableToken();

          final numbers = <int>[];
          final errors = <SquadronException>[];

          final sub = pool.infiniteWithErrors(token).listen(
                (number) => numbers.add(number),
                onError: (ex) => errors.add(ex),
                cancelOnError: false,
              );

          sub.cancel();

          await Future.delayed(TestDelays.delay);

          expect(numbers, isEmpty);
          expect(errors, isEmpty);
        });
      });
    });
  });
}
