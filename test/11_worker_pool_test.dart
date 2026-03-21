// ignore_for_file: file_names

import 'dart:async';

import 'package:cancelation_token/cancelation_token.dart';
import 'package:squadron/squadron.dart';
import 'package:test/test.dart';

import 'src/test_context.dart';
import 'src/utils.dart';
import 'test_concurrency.dart';
import 'test_delay.dart';
import 'test_exception.dart';
import 'test_extensions.dart';
import 'worker_services/cache_service_worker.dart';
import 'worker_services/error_service.dart';
import 'worker_services/error_service_worker.dart';
import 'worker_services/prime_service_worker.dart';
import 'worker_services/primes.dart';
import 'worker_services/test_service_worker.dart';

Future<void> main() => TestContext.run(execute);

const testScript = '10_worker_pool_test.dart';

void execute(TestContext? tc) {
  if (tc == null) return;

  tc.launch(() {
    tc.group('- SQUADRON WORKER - POOL', () {
      setUp(() {
        Squadron.disableBrowserCache = true;
      });

      tearDown(() {
        Squadron.disableBrowserCache = false;
      });

      tc.test(
          '- Prime worker pool + cache worker',
          () => CacheWorker(tc).startAndRunTest((cache) =>
              PrimeWorkerPool(tc, cache, small).startAndRunTest((p) async {
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
              })));

      tc.test(
          '- Worker pool monitoring',
          () => TestWorkerPool(tc, medium).startAndRunTest((p) async {
                final count = 2 * p.maxConcurrency + 1;

                // starting the pool must have instantiated minWorkers workers
                expect(p.size, p.minWorkers);

                final tasks = <Future>[];
                for (var i = 0; i < count; i++) {
                  tasks.add(p.io(ms: TestDelay.tick.inMilliseconds * 10));
                }

                // let the pool kick off some tasks: it must be running at full speed
                await Future.delayed(TestDelay.tick * 5);
                expect(p.size, p.maxWorkers);

                // install the worker monitor
                var stopped = 0;
                final timer = Timer.periodic(TestDelay.resolution, (timer) {
                  stopped +=
                      p.stop((w) => w.getStats().idleTime > TestDelay.tick);
                });

                try {
                  // let tasks continue their work for a short while
                  await Future.delayed(TestDelay.tick * 2);

                  // while there is pending work, no worker should be stopped
                  expect(stopped, lessThan(p.maxWorkers));

                  // wait until completion, then go idle
                  await Future.wait(tasks);

                  // the extra workers should have been stopped
                  expect(stopped, isPositive);

                  // and the pool should be back to minimum size
                  await Future.delayed(TestDelay.tick * 2);
                  expect(p.size, p.minWorkers);
                } finally {
                  timer.cancel();
                }
              }));

      tc.group('- Error handling', () {
        tc.test(
            '- Failed initialization',
            () => TestWorkerPool.throws(tc).runTest((p) async {
                  await expectLater(p.start(), failsWith<WorkerException>());
                  await expectLater(p.ping(), failsWith<CanceledException>());
                  expect(p.size, isZero);
                }));

        tc.test(
            '- Missing command',
            () => TestWorkerPool.missingStartRequest(tc).runTest((p) async {
                  await expectLater(p.start(), failsWith<SquadronError>());
                  await expectLater(p.ping(), failsWith<CanceledException>());
                  expect(p.size, isZero);
                }),
            skip: tc.entryPoints.missingStartRequest == null);

        tc.test(
            '- Invalid command ID',
            () => TestWorkerPool.invalid(tc).runTest((p) async {
                  await expectLater(p.start(), failsWith<SquadronError>());
                  await expectLater(p.ping(), failsWith<CanceledException>());
                  expect(p.size, isZero);
                }));

        tc.test(
            '- Dart Exception',
            () => ErrorWorkerPool(tc, small).runTest((p) async {
                  try {
                    await p.throwException();
                    throw unexpectedSuccess('throwException()');
                  } on WorkerException catch (ex) {
                    expect(ex, reports('intentional exception'));
                    expect(ex.stackTrace, hasCalled('throwException'));
                  }
                  expect(p.stats.fold<int>(0, (t, s) => t + s.totalErrors), 1);
                }));

        tc.test(
            '- WorkerException',
            () => ErrorWorkerPool(tc, small).runTest((p) async {
                  try {
                    await p.throwWorkerException();
                    throw unexpectedSuccess('throwWorkerException()');
                  } on WorkerException catch (ex) {
                    expect(ex, reports('intentional worker exception'));
                    expect(ex.stackTrace, hasCalled('throwWorkerException'));
                  }
                  expect(p.stats.fold<int>(0, (t, s) => t + s.totalErrors), 1);
                }));

        tc.test(
            '- TaskTimeOutException',
            () => ErrorWorkerPool(tc, small).runTest((p) async {
                  try {
                    await p.throwTaskTimeOutException();
                    throw unexpectedSuccess('timeOut()');
                  } on TimeoutException catch (ex) {
                    expect(ex, reports('intentional timeout exception'));
                  }
                }));

        tc.test(
            '- CanceledException',
            () => ErrorWorkerPool(tc, small).runTest((p) async {
                  try {
                    await p.throwCanceledException();
                    throw unexpectedSuccess('cancel()');
                  } on CanceledException catch (ex) {
                    expect(ex, reports('intentional canceled exception'));
                  }
                }));

        tc.test(
            '- TestException (unregistered)',
            () => ErrorWorkerPool(tc, small).runTest((p) async {
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
                }));

        tc.test(
            '- TestException (registered)',
            () => ErrorWorkerPool(tc, small).runTest((p) async {
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
                }));
      });

      tc.group('- Performance', () {
        tc.test(
            '- Non-streaming (prime worker)',
            () => PrimeWorkerPool(tc).runTest((p) async {
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
                    await TestDelay.pause(ticks: 1);
                    progress = counter.snapshot;
                  }
                  expect(progress.totalCount, isPositive);
                  expect(progress.totalErrors, isZero);
                  expect(progress.totalTimeInMicroseconds, isPositive);

                  await Future.wait(tasks);

                  final end = counter.snapshot;
                  expect(end.totalCount,
                      greaterThanOrEqualTo(progress.totalCount));
                  expect(end.totalErrors, isZero);
                  expect(end.totalTimeInMicroseconds,
                      greaterThanOrEqualTo(progress.totalTimeInMicroseconds));
                }));

        tc.test(
            '- Streaming (prime worker)',
            () => PrimeWorkerPool(tc).runTest((p) async {
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
                    await TestDelay.pause(ticks: 1);
                    progress = counter.snapshot;
                  }
                  expect(progress.totalCount, isPositive);
                  expect(progress.totalErrors, isZero);
                  expect(progress.totalTimeInMicroseconds, isPositive);

                  await Future.wait(tasks);

                  final end = counter.snapshot;
                  expect(end.totalCount,
                      greaterThanOrEqualTo(progress.totalCount));
                  expect(end.totalErrors, isZero);
                  expect(end.totalTimeInMicroseconds,
                      greaterThanOrEqualTo(progress.totalTimeInMicroseconds));
                }));
      });

      tc.test(
          '- Stopped pool will not accept new requests',
          () => TestWorkerPool(tc, oneIo).runTest((p) async {
                final n = await p.delayedLong(-1);
                expect(n, -1);

                p.stop();

                try {
                  final n = await p.delayedLong(-1);
                  throw unexpectedSuccess('delayed()', n);
                } on SquadronError catch (ex) {
                  expect(ex, reports('cannot accept new requests'));
                  expect(ex, reports('stopped'));
                }
              }));

      tc.test(
          '- Restarted pool will serve new requests',
          () => TestWorkerPool(tc, twoIo).startAndRunTest((p) async {
                expect(p.size, isPositive);

                var n = await p.delayedLong(-1);
                expect(n, -1);

                p.stop();

                expect(p.stopped, isTrue);

                await TestDelay.pause(ticks: 1);
                expect(p.size, isZero);

                try {
                  n = await p.delayedLong(-1);
                  throw unexpectedSuccess('delayed()', n);
                } on SquadronError catch (ex) {
                  expect(ex, reports('cannot accept new requests'));
                  expect(ex, reports('stopped'));
                }

                // restart
                p.start();

                n = await p.delayedLong(-2);
                expect(n, -2);
              }));

      tc.test(
          '- Stopping a pool does not prevent processing of pending tasks',
          () => TestWorkerPool(tc, threeCpu).startAndRunTest((p) async {
                final count = 2 * p.maxConcurrency + p.maxWorkers;
                final digits = <int>[], tasks = <Future>[];
                for (var i = 0; i < count; i++) {
                  tasks.add(p.delayedLong(i).then(digits.add));
                }

                await TestDelay.pause(ticks: 1);
                p.stop();

                expect(p.stopped, isTrue);
                expect(p.pendingWorkload, isNonNegative);
                expect(digits, hasLength(lessThanOrEqualTo(count)));

                await Future.wait(tasks);

                expect(p.stopped, isTrue);
                expect(p.pendingWorkload, isZero);
                expect(digits, hasLength(count));

                await TestDelay.pause(ticks: 1);
                expect(p.size, isZero);
              }));

      tc.test(
          '- Pool termination',
          () => TestWorkerPool(tc, threeCpu).startAndRunTest((p) async {
                final duration = TestDelay.tick * 10;

                Timer(duration * 0.5, () {
                  p.terminate();
                  expect(p.stopped, isTrue);
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
              }));

      tc.group('- Streaming - with multiple errors', () {
        tc.test(
            '- With cancelOnError = false',
            () => TestWorkerPool(tc).startAndRunTest((p) async {
                  final token = CancelableToken();

                  final done = Completer(),
                      numbers = <int>[],
                      errors = <SquadronException>[];

                  p.infiniteWithErrors(token).listen(
                    numbers.add, // receives 0 + odd numbers: 0, 1, 3, 5
                    onError: (ex) {
                      errors.add(
                          ex); // receives errors for even numbers: #2, #4, #6
                      if (errors.length >= 3) {
                        token.cancel(CanceledException('forced'));
                      }
                    },
                    onDone: done.complete,
                    cancelOnError: false,
                  );

                  await done.future;

                  expect(numbers, hasLength(4));
                  expect(errors, hasLength(4));
                  final messages = errors.map((e) => e.message.toLowerCase());
                  expect(messages.where((m) => m.contains('error #')),
                      hasLength(3));
                  expect(messages.where((m) => m.contains('forced')),
                      hasLength(1));
                }));

        tc.test(
            '- With cancelOnError = true',
            () => TestWorkerPool(tc).startAndRunTest((p) async {
                  final numbers = <int>[];

                  try {
                    final res = await p
                        .infiniteWithErrors()
                        .listen(numbers.add, cancelOnError: true)
                        .asFuture();
                    throw unexpectedSuccess('infiniteWithErrors()', res);
                  } on WorkerException catch (ex) {
                    expect(numbers, [0, 1]);
                    expect(ex, reports('error #2'));
                  }
                }));

        tc.test(
            '- With "await for"',
            () => TestWorkerPool(tc).startAndRunTest((p) async {
                  final numbers = <int>[];
                  try {
                    await for (var number in p.infiniteWithErrors()) {
                      numbers.add(number);
                    }
                    throw unexpectedSuccess('infiniteWithErrors()', null);
                  } on WorkerException catch (ex) {
                    expect(numbers, [0, 1]);
                    expect(ex, reports('error #2'));
                  }
                }));

        tc.test(
            '- Throwing in "await for"',
            () => TestWorkerPool(tc).startAndRunTest((p) async {
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
                }));

        tc.test(
            '- Pause & resume',
            () => TestWorkerPool(tc).startAndRunTest((p) async {
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
                  await TestDelay.pause(ticks: 4);
                  expect(numbers, isEmpty);
                  expect(errors, isEmpty);
                  // resume
                  resume();

                  await TestDelay.pause(ticks: 4);
                  pause();
                  pause();
                  await TestDelay.pause(ticks: 4);
                  resume();
                  await TestDelay.pause(ticks: 4);
                  resume();
                  await TestDelay.pause(ticks: 4);

                  sub.cancel();

                  expect(numbers, hasLength(greaterThan(countNumbers)));
                  expect(errors, hasLength(greaterThan(countErrors)));
                  expect(errors, everyElement(doesNotReport('by request')));
                }));

        tc.test(
            '- Pause/resume/cancel with a StreamTask',
            // at most one task --> one CPU thread
            () => TestWorkerPool(tc, oneCpu).startAndRunTest((p) async {
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

                  await TestDelay.pause(ticks: 2);

                  expect(numbers0, isEmpty);
                  expect(errors0, isEmpty);
                  expect(numbers1, isEmpty);
                  expect(errors1, isEmpty);

                  sub0.resume();
                  sub1.resume();

                  await TestDelay.pause(ticks: 4);

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
                  await TestDelay.pause(ticks: 4);

                  expect(numbers0, hasLength(numbersCount0));
                  expect(errors0, hasLength(errorsCount0 + 1));
                  expect(errors0.last, reports('by token #0'));
                  expect(numbers1, isEmpty);
                  expect(errors1, isEmpty);

                  // resume: buffered event should be processed
                  sub1.resume();
                  await TestDelay.pause(ticks: 2);

                  expect(numbers0, hasLength(numbersCount0));
                  expect(errors0, hasLength(errorsCount0 + 1));
                  expect(numbers1, isNotEmpty);
                  expect(errors1, isNotEmpty);

                  // terminate
                  await Future.wait([sub0.cancel(), sub1.cancel()]);

                  expect(await p.getPendingInfiniteWithErrors(), isZero);
                }));

        tc.test(
            '- Early cancelation',
            () => TestWorkerPool(tc).startAndRunTest((p) async {
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

                  await Future.delayed(TestDelay.tick);

                  // now the task has completed
                  expect(task.isPending, isFalse);
                  expect(task.isRunning, isFalse);
                  expect(task.isCanceled, isFalse);
                  expect(task.isFinished, isTrue);

                  expect(numbers, isEmpty);
                  expect(errors, isEmpty);
                }));

        tc.test(
            '- Streaming task early cancelation',
            () => TestWorkerPool(tc).startAndRunTest((p) async {
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

                  await TestDelay.pause(ticks: 1);

                  expect(numbers, isEmpty);
                  expect(errors, hasLength(1));
                  expect(errors.first, isA<TaskCanceledException>());

                  sub.cancel();
                }));
      });
    });
  });
}
