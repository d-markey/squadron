// ignore_for_file: file_names

@TestOn('vm || browser')
library;

import 'dart:async';

import 'package:cancelation_token/cancelation_token.dart';
import 'package:squadron/squadron.dart';
import 'package:test/test.dart';
import 'package:using/using.dart';

import 'src/test_context.dart';
import 'src/utils.dart';
import 'test_constants.dart';
import 'test_exception.dart';
import 'worker_services/cache_service_worker.dart';
import 'worker_services/error_service.dart';
import 'worker_services/error_service_worker.dart';
import 'worker_services/prime_service_worker.dart';
import 'worker_services/test_service_worker.dart';

Future<void> main() => TestContext.run(execute);

const testScript = '10_worker_pool_test.dart';

void execute(TestContext? tc) {
  if (tc == null) return;

  tc.launch(() {
    tc.group('- SQUADRON WORKER - POOL', () {
      tc.test('- Prime worker pool + cache worker', () async {
        await CacheWorker(tc).useAsync((cache) async {
          // important, the cache worker must be started to share its channel
          await cache.start();
          await PrimeWorkerPool(tc, cache, concurrency_222).useAsync((p) async {
            final count = 2 * p.maxConcurrency + 1;
            final completedTasks = <int>[], tasks = <Future>[];
            for (var i = 0; i <= count; i++) {
              tasks.add(p.isPrime(i).then((_) => completedTasks.add(i)));
            }

            await Future.wait(tasks);

            expect(completedTasks, hasLength(tasks.length));
            expect(p.stats, hasLength(p.maxWorkers));

            final maxWorkerWorkload = p.concurrencySettings.maxParallel;
            expect(p.stats.map((s) => s.maxWorkload),
                everyElement(lessThanOrEqualTo(maxWorkerWorkload)));
          });
        });
      });

      tc.test('- Worker pool monitoring', () async {
        await TestWorkerPool(tc, concurrency_253).useAsync((p) async {
          final count = 2 * p.maxConcurrency + 1;

          // starting the pool will instantiate minWorkers workers
          await p.start();
          expect(p.size, p.minWorkers);

          final tasks = <Future>[];
          for (var i = 0; i < count; i++) {
            tasks.add(p.io(ms: delay_80ms.inMilliseconds * 5));
          }

          // let the pool kick off some tasks: it must be running at full speed
          await Future.delayed(delay_80ms * 2);
          expect(p.size, p.maxWorkers);

          // install the worker monitor
          var stopped = 0;
          final timer = Timer.periodic(delay_80ms * 0.5, (timer) {
            stopped += p.stop((w) => w.idleTime > delay_80ms);
          });

          try {
            // let tasks continue their work for a short while
            await Future.delayed(delay_80ms * 2);

            // while there is pending work, no worker should be stopped
            expect(stopped, lessThan(p.maxWorkers));

            // wait until completion, then go idle
            await Future.wait(tasks);

            // the extra workers should have been stopped
            expect(stopped, isPositive);

            // and the pool should be back to minimum size
            await Future.delayed(delay_20ms);
            expect(p.size, p.minWorkers);
          } finally {
            timer.cancel();
          }
        });
      });

      tc.group('- Error handling', () {
        tc.test('- Failed initialization', () async {
          await TestWorkerPool.throws(tc).useAsync((p) async {
            await expectLater(p.start(), failsWith<WorkerException>());
            await expectLater(p.ping(), failsWith<CanceledException>());
            expect(p.size, isZero);
          });
        });

        tc.test('- Missing command', () async {
          await TestWorkerPool.missingStartRequest(tc).useAsync((p) async {
            await expectLater(p.start(), failsWith<SquadronError>());
            await expectLater(p.ping(), failsWith<CanceledException>());
            expect(p.size, isZero);
          });
        }, skip: tc.entryPoints.missingStartRequest == null);

        tc.test('- Invalid command ID', () async {
          await TestWorkerPool.invalid(tc).useAsync((p) async {
            await expectLater(p.start(), failsWith<SquadronError>());
            await expectLater(p.ping(), failsWith<CanceledException>());
            expect(p.size, isZero);
          });
        });

        tc.test('- Dart Exception', () async {
          await ErrorWorkerPool(tc, concurrency_222).useAsync((p) async {
            try {
              await p.throwException();
              throw unexpectedSuccess('throwException()');
            } on WorkerException catch (ex) {
              expect(ex, reports('intentional exception'));
              expect(ex.stackTrace, hasCalled('throwException'));
            }
            expect(p.stats.fold<int>(0, (t, s) => t + s.totalErrors), 1);
          });
        });

        tc.test('- WorkerException', () async {
          await ErrorWorkerPool(tc, concurrency_222).useAsync((p) async {
            try {
              await p.throwWorkerException();
              throw unexpectedSuccess('throwWorkerException()');
            } on WorkerException catch (ex) {
              expect(ex, reports('intentional worker exception'));
              expect(ex.stackTrace, hasCalled('throwWorkerException'));
            }
            expect(p.stats.fold<int>(0, (t, s) => t + s.totalErrors), 1);
          });
        });

        tc.test('- TaskTimeOutException', () async {
          await ErrorWorkerPool(tc, concurrency_222).useAsync((p) async {
            try {
              await p.throwTaskTimeOutException();
              throw unexpectedSuccess('timeOut()');
            } on TimeoutException catch (ex) {
              expect(ex, reports('intentional timeout exception'));
            }
          });
        });

        tc.test('- CanceledException', () async {
          await ErrorWorkerPool(tc, concurrency_222).useAsync((p) async {
            try {
              await p.throwCanceledException();
              throw unexpectedSuccess('cancel()');
            } on CanceledException catch (ex) {
              expect(ex, reports('intentional canceled exception'));
            }
          });
        });

        tc.test('- TestException (unregistered)', () async {
          await ErrorWorkerPool(tc, concurrency_222).useAsync((p) async {
            try {
              await p.throwTestException();
              throw unexpectedSuccess('cancel()');
            } on WorkerException catch (ex) {
              expect(ex, isNotA<TestException>());
              expect(ex, reports('Failed to deserialize'));
              expect(ex, reports('#TEST'));
              expect(ex.command, ErrorService.throwTestExceptionCommand);
            } finally {
              p.exceptionManager.unregister(TestException.typeId);
            }
          });
        });

        tc.test('- TestException (registered)', () async {
          await ErrorWorkerPool(tc, concurrency_222).useAsync((p) async {
            try {
              p.exceptionManager.register(
                TestException.typeId,
                TestException.deserialize,
              );
              await p.throwTestException();
              throw unexpectedSuccess('cancel()');
            } on TestException catch (ex) {
              expect(ex, reports('intentional TEST exception'));
              expect(ex.stackTrace, hasCalled('throwTestException'));
              expect(ex.command, ErrorService.throwTestExceptionCommand);
            } finally {
              p.exceptionManager.unregister(TestException.typeId);
            }
          });
        });
      });

      tc.group('- Performance', () {
        tc.test('- Non-streaming (prime worker)', () async {
          await PrimeWorkerPool(tc).useAsync((p) async {
            final count = 3 * p.maxConcurrency + 1;
            final counter = PerfCounter('perf'), tasks = <Future>[];
            for (var i = 0; i < count; i++) {
              tasks.add(p.isPrime(largePrimes.last, counter));
            }

            final start = counter.snapshot;
            expect(start.totalCount, isZero);
            expect(start.totalErrors, isZero);
            expect(start.totalTimeInMicroseconds, isZero);

            await tasks.first;

            var progress = counter.snapshot;
            if (progress.totalCount == 0) {
              await Future.delayed(delay_20ms);
              progress = counter.snapshot;
            }
            expect(progress.totalCount, isPositive);
            expect(progress.totalErrors, isZero);
            expect(progress.totalTimeInMicroseconds, isPositive);

            await Future.wait(tasks);

            final end = counter.snapshot;
            expect(end.totalCount, greaterThanOrEqualTo(progress.totalCount));
            expect(end.totalErrors, isZero);
            expect(end.totalTimeInMicroseconds,
                greaterThanOrEqualTo(progress.totalTimeInMicroseconds));
          });
        });

        tc.test('- Streaming (prime worker)', () async {
          await PrimeWorkerPool(tc).useAsync((p) async {
            final count = 3 * p.maxConcurrency + 1;
            // start count tasks and measure performance
            final counter = PerfCounter('perf'), tasks = <Future>[];
            for (var i = 0; i < count; i++) {
              tasks.add(p.getPrimes(0, 1000, counter).drain());
            }

            final start = counter.snapshot;
            expect(start.totalCount, isZero);
            expect(start.totalErrors, isZero);
            expect(start.totalTimeInMicroseconds, isZero);

            await tasks.first;

            var progress = counter.snapshot;
            if (progress.totalCount == 0) {
              await Future.delayed(delay_20ms);
              progress = counter.snapshot;
            }
            expect(progress.totalCount, isPositive);
            expect(progress.totalErrors, isZero);
            expect(progress.totalTimeInMicroseconds, isPositive);

            await Future.wait(tasks);

            final end = counter.snapshot;
            expect(end.totalCount, greaterThanOrEqualTo(progress.totalCount));
            expect(end.totalErrors, isZero);
            expect(end.totalTimeInMicroseconds,
                greaterThanOrEqualTo(progress.totalTimeInMicroseconds));
          });
        });
      });

      tc.test('- Stopped pool will not accept new requests', () async {
        await TestWorkerPool(tc, ConcurrencySettings.oneIoThread)
            .useAsync((p) async {
          final n = await p.delayed(-1);
          expect(n, -1);

          p.stop();

          try {
            final n = await p.delayed(-1);
            throw unexpectedSuccess('delayed()', n);
          } on SquadronError catch (ex) {
            expect(ex, reports('cannot accept new requests'));
            expect(ex, reports('stopped'));
          }
        });
      });

      tc.test('- Restarted pool will serve new requests', () async {
        await TestWorkerPool(tc, ConcurrencySettings.twoIoThreads)
            .useAsync((p) async {
          await p.start();
          expect(p.size, isPositive);

          var n = await p.delayed(-1);
          expect(n, -1);

          p.stop();

          expect(p.stopped, isTrue);

          await Future.delayed(delay_20ms);
          expect(p.size, isZero);

          try {
            n = await p.delayed(-1);
            throw unexpectedSuccess('delayed()', n);
          } on SquadronError catch (ex) {
            expect(ex, reports('cannot accept new requests'));
            expect(ex, reports('stopped'));
          }

          // restart
          p.start();

          n = await p.delayed(-2);
          expect(n, -2);
        });
      });

      tc.test('- Stopping a pool does not prevent processing of pending tasks',
          () async {
        await TestWorkerPool(tc, ConcurrencySettings.threeCpuThreads)
            .useAsync((p) async {
          final count = 2 * p.maxConcurrency + p.maxWorkers;
          final digits = <int>[], tasks = <Future>[];
          for (var i = 0; i < count; i++) {
            tasks.add(p.delayed(i).then(digits.add));
          }

          await Future.delayed(delay_80ms);
          p.stop();

          expect(p.stopped, isTrue);
          expect(p.pendingWorkload, isNonNegative);
          expect(digits, hasLength(lessThanOrEqualTo(count)));

          await Future.wait(tasks);

          expect(p.stopped, isTrue);
          expect(p.pendingWorkload, isZero);
          expect(digits, hasLength(count));

          await Future.delayed(delay_20ms);
          expect(p.size, isZero);
        });
      });

      tc.test('- Pool termination', () async {
        await TestWorkerPool(tc, ConcurrencySettings.threeCpuThreads)
            .useAsync((p) async {
          await p.start();
          final duration = delay_80ms * 10;

          Timer(duration * 0.5, () {
            p.terminate();
            expect(p.stopped, true);
          });

          try {
            final futures = [
              p.cpu(ms: duration.inMilliseconds),
              p.cpu(ms: duration.inMilliseconds),
              p.cpu(ms: duration.inMilliseconds),
              p.cpu(ms: duration.inMilliseconds),
              p.cpu(ms: duration.inMilliseconds),
              p.cpu(ms: duration.inMilliseconds),
            ];
            await Future.wait(futures);
            unexpectedSuccess('cpu tasks weer not terminated');
          } on TaskTerminatedException {
            // expected
          }
        });
      });

      tc.group('- Streaming - with multiple errors', () {
        tc.test('- With cancelOnError = false', () async {
          await TestWorkerPool(tc).useAsync((p) async {
            final token = CancelableToken();

            final done = Completer(),
                numbers = <int>[],
                errors = <SquadronException>[];

            p.infiniteWithErrors(token).listen(
              numbers.add,
              onError: (ex) {
                errors.add(ex);
                if (errors.length >= 3) {
                  token.cancel(CanceledException('forced'));
                }
              },
              onDone: done.complete,
              cancelOnError: false,
            );

            await done.future;

            expect(numbers, hasLength(greaterThan(3 * 2)));
            expect(errors, hasLength(greaterThan(3)));
            final messages = errors.map((e) => e.message.toLowerCase());
            expect(messages.where((m) => m.contains('error #')), hasLength(3));
            expect(messages.where((m) => m.contains('forced')), hasLength(1));
          });
        });

        tc.test('- With cancelOnError = true', () async {
          await TestWorkerPool(tc).useAsync((p) async {
            final numbers = <int>[];

            try {
              final res = await p
                  .infiniteWithErrors()
                  .listen(numbers.add, cancelOnError: true)
                  .asFuture();
              throw unexpectedSuccess('infiniteWithErrors()', res);
            } on WorkerException catch (ex) {
              expect(ex, reports('error #\\d+'));
            }

            expect(numbers, [0, 1, 2]);
          });
        });

        tc.test('- With "await for"', () async {
          await TestWorkerPool(tc).useAsync((p) async {
            final numbers = <int>[];
            try {
              await for (var number in p.infiniteWithErrors()) {
                numbers.add(number);
              }
              throw unexpectedSuccess('infiniteWithErrors()', null);
            } on WorkerException catch (ex) {
              expect(ex, reports('error #\\d+'));
            }

            expect(numbers, [0, 1, 2]);
          });
        });

        tc.test('- Throwing in "await for"', () async {
          await TestWorkerPool(tc).useAsync((p) async {
            final numbers = <int>[];
            try {
              await for (var number in p.infiniteWithErrors()) {
                if (numbers.isNotEmpty) {
                  throw WorkerException('Client-side exception');
                }
                numbers.add(number);
              }
              throw unexpectedSuccess('infiniteWithErrors()', null);
            } on WorkerException catch (ex) {
              expect(ex, reports('Client-side exception'));
            }

            expect(numbers, [0]);
          });
        });

        tc.test('- Pause & resume', () async {
          await TestWorkerPool(tc).useAsync((p) async {
            final numbers = <int>[], errors = <SquadronException>[];

            final token = CancelableToken();
            final sub = p.infiniteWithErrors(token).listen(
                  numbers.add,
                  onError: errors.add,
                  cancelOnError: false,
                );

            int countNumbers = 0, countErrors = 0, paused = 0;

            void pause() {
              sub.pause();
              if (paused == 0) {
                expect(numbers, hasLength(greaterThan(countNumbers)));
                expect(errors, hasLength(greaterThan(countErrors)));
                countNumbers = numbers.length;
                countErrors = errors.length;
              } else {
                expect(numbers, hasLength(countNumbers));
                expect(errors, hasLength(countErrors));
              }
              paused++;
            }

            void resume() {
              expect(numbers, hasLength(countNumbers));
              expect(errors, hasLength(countErrors));
              sub.resume();
              if (paused > 0) {
                paused--;
              }
            }

            // this call should have no effect
            resume();

            // pause immediately
            sub.pause();
            expect(numbers, isEmpty);
            expect(errors, isEmpty);
            await Future.delayed(delay_80ms * 4);
            expect(numbers, isEmpty);
            expect(errors, isEmpty);
            // resume
            resume();

            await Future.delayed(delay_80ms * 4);
            pause();
            pause();
            await Future.delayed(delay_80ms * 4);
            resume();
            await Future.delayed(delay_80ms * 4);
            resume();
            await Future.delayed(delay_80ms * 4);

            sub.cancel();

            expect(numbers, hasLength(greaterThan(countNumbers)));
            expect(errors, hasLength(greaterThan(countErrors)));
            expect(errors, everyElement(doesNotReport('by request')));
          });
        });

        tc.test('- Pause/resume/cancel with a StreamTask', () async {
          // at most one task
          await TestWorkerPool(tc, ConcurrencySettings.oneCpuThread)
              .useAsync((p) async {
            final numbers0 = <int>[], errors0 = <SquadronException>[];
            final token0 = CancelableToken();
            final task0 = p.infiniteWithErrorsTask(token0);
            final sub0 = task0.stream.listen(
              numbers0.add,
              onError: errors0.add,
              cancelOnError: false,
            );

            // because concurrency settings only allow 1 task at a time, this task
            // will not start streaming before the previous one is finished
            final numbers1 = <int>[], errors1 = <SquadronException>[];
            final token1 = CancelableToken();
            final task1 = p.infiniteWithErrorsTask(token1);
            final sub1 = task1.stream.listen(
              numbers1.add,
              onError: errors1.add,
              cancelOnError: false,
            );

            sub0.pause();
            sub1.pause();

            await Future.delayed(delay_80ms * 2);

            expect(numbers0, isEmpty);
            expect(errors0, isEmpty);
            expect(numbers1, isEmpty);
            expect(errors1, isEmpty);

            sub0.resume();
            sub1.resume();

            await Future.delayed(delay_80ms * 2);

            expect(numbers0, isNotEmpty);
            expect(errors0, isNotEmpty);
            expect(numbers1, isEmpty);
            expect(errors1, isEmpty);

            // pause second stream, cancel first stream task
            sub1.pause();
            await token0.cancel(CanceledException('by token #0'));

            final numbersCount0 = numbers0.length,
                errorsCount0 = errors0.length;

            expect(numbers1, isEmpty);
            expect(errors1, isEmpty);

            // the second stream should be buffering events
            await Future.delayed(delay_80ms * 4);

            expect(numbers0, hasLength(numbersCount0));
            expect(errors0, hasLength(errorsCount0 + 1));
            expect(errors0.last, reports('by token #0'));
            expect(numbers1, isEmpty);
            expect(errors1, isEmpty);

            // resume: buffered event should be processed
            sub1.resume();
            await Future.delayed(delay_80ms * 4);

            expect(numbers0, hasLength(numbersCount0));
            expect(errors0, hasLength(errorsCount0 + 1));
            expect(numbers1, isNotEmpty);
            expect(errors1, isNotEmpty);

            // terminate
            await Future.wait([sub0.cancel(), sub1.cancel()]);

            expect(await p.getPendingInfiniteWithErrors(), isZero);
          });
        });

        tc.test('- Early cancelation', () async {
          await TestWorkerPool(tc).useAsync((p) async {
            final numbers = <int>[], errors = <SquadronException>[];
            final task = p.infiniteWithErrorsTask();

            task.stream
                .listen(
                  numbers.add,
                  onError: errors.add,
                  cancelOnError: false,
                )
                .cancel();

            // the stream subscription is cancelled
            // but the task is still pending
            expect(task.isPending, isTrue);
            expect(task.isRunning, isFalse);
            expect(task.isCanceled, isFalse);
            expect(task.isFinished, isFalse);

            // now the task has completed
            await Future.delayed(delay_80ms * 2);

            expect(task.isPending, isFalse);
            expect(task.isRunning, isFalse);
            expect(task.isCanceled, isFalse);
            expect(task.isFinished, isTrue);

            expect(numbers, isEmpty);
            expect(errors, isEmpty);
          });
        });
        tc.test('- Streaming task early cancelation', () async {
          await TestWorkerPool(tc).useAsync((p) async {
            final numbers = <int>[], errors = <SquadronException>[];
            final task = p.infiniteWithErrorsTask();
            final stream = task.stream;

            task.cancel();

            expect(task.isPending, isFalse);
            expect(task.isRunning, isFalse);
            expect(task.isCanceled, isTrue);
            expect(task.isFinished, isFalse);

            final sub = stream.listen(
              numbers.add,
              onError: errors.add,
              cancelOnError: false,
            );

            await Future.delayed(delay_20ms);

            expect(numbers, isEmpty);
            expect(errors, hasLength(1));
            expect(errors.first, isA<TaskCanceledException>());

            sub.cancel();
          });
        });
      });
    });
  });
}
