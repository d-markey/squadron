@TestOn('vm || browser')
library;

import 'dart:async';

import 'package:cancelation_token/cancelation_token.dart';
import 'package:squadron/squadron.dart';
import 'package:test/test.dart';

import 'classes/test_context.dart';
import 'classes/utils.dart';
import 'worker_services/delays.dart';
import 'worker_services/test_service_worker.dart';

const concurrencySettings_222 =
    ConcurrencySettings(minWorkers: 2, maxWorkers: 2, maxParallel: 2);

void main() async {
  final testContext = await TestContext.init('');
  execute(testContext);
}

String testScript = 'cancelation_test.dart';

void execute(TestContext tc) {
  tc.run(() {
    late TestWorkerPool pool;
    late TestWorker worker;

    setUpAll(() async {
      pool = TestWorkerPool(tc, concurrencySettings_222);
      await pool.start();
      worker = TestWorker(tc);
      await worker.start();
    });

    tearDownAll(() {
      pool.release();
      worker.release();
    });

    tc.group("- Cancelation", () {
      tc.group('- ValueTask', () {
        tc.test('- immediate with pool.cancel()', () async {
          final digits = <int>[];
          int errors = 0;

          final tasks = <Future>[];
          for (var i = 0; i < 2 * pool.maxConcurrency + 1; i++) {
            tasks.add(pool.delayed(i).then((value) {
              digits.add(value);
            }).catchError((e) {
              errors += 1;
            }));
          }

          pool.cancel();

          await Future.wait(tasks);

          expect(digits, isEmpty);
          expect(errors, isPositive);
          expect(digits.length + errors, equals(2 * pool.maxConcurrency + 1));
        });

        tc.test('- immediate with pool.cancel(task)', () async {
          final task = pool.delayedIdentityTask(3);
          pool.cancel(task, 'Immediate cancelation');

          try {
            final value = await task.value;
            throw unexpectedSuccess('delayedIdentityTask()', value);
          } on CanceledException catch (ex) {
            lowerCaseCheck(ex.message, contains('immediate cancelation'));
          }
        });

        tc.test('- immediate with task.cancel()', () async {
          final task = pool.delayedIdentityTask(3)
            ..cancel('Immediate cancelation');

          try {
            final value = await task.value;
            throw unexpectedSuccess('delayedIdentityTask()', value);
          } on CanceledException catch (ex) {
            lowerCaseCheck(ex.message, contains('immediate cancelation'));
          }
        });

        tc.test('- with pool.cancel()', () async {
          final digits = <int>[];
          int errors = 0;

          final tasks = <Future>[];
          for (var i = 0; i < 2 * pool.maxConcurrency + 1; i++) {
            tasks.add(pool.delayed(i).then((value) {
              digits.add(value);
            }).catchError((e) {
              errors += 1;
            }));
          }

          await Future.delayed(TestDelays.delay * 2.5);
          pool.cancel();

          await Future.wait(tasks);

          expect(digits.length, isPositive);
          expect(errors, isPositive);
          expect(digits.length + errors, equals(2 * pool.maxConcurrency + 1));
        });

        tc.test('- with pool.cancel(task)', () async {
          final digits = <int>[];
          int errors = 0;

          final tasks = <ValueTask>[];
          final futures = <Future>[];
          for (var i = 0; i < 3 * pool.maxConcurrency + 1; i++) {
            final task = pool.delayedIdentityTask(i);
            tasks.add(task);
            futures.add(task.value.then((value) {
              digits.add(value);
            }).catchError((e) {
              // swallow error
              errors += 1;
            }));
          }

          final firstTask = tasks[0];
          pool.cancel(firstTask);
          expect(firstTask.isCanceled, isTrue);
          expect(firstTask.isRunning, isFalse);
          expect(firstTask.isFinished, isFalse);

          await Future.delayed(TestDelays.delay * 1.8);
          final lastTask = tasks[3 * pool.maxConcurrency];
          pool.cancel(lastTask);
          expect(lastTask.isCanceled, isTrue);
          expect(lastTask.runningTime.inMicroseconds, isZero);

          await Future.wait(futures);

          final running = tasks.where((t) => t.isRunning);
          final canceled = tasks.where((t) => t.isCanceled);
          final finished = tasks.where((t) => t.isFinished);

          expect(running, isEmpty);
          expect(canceled.length, equals(2));
          expect(finished.length + canceled.length, equals(tasks.length));

          expect(errors, equals(2));
          expect(digits.length + errors, equals(tasks.length));
        });

        tc.test('- with task.cancel()', () async {
          final digits = <int>[];
          int errors = 0;

          final tasks = <ValueTask>[];
          final futures = <Future>[];
          for (var i = 0; i < 3 * pool.maxConcurrency + 1; i++) {
            final task = pool.delayedIdentityTask(i);
            tasks.add(task);
            futures.add(task.value.then((value) {
              digits.add(value);
            }).catchError((e) {
              // swallow error
              errors += 1;
            }));
          }

          tasks[0].cancel();
          expect(tasks[0].isCanceled, isTrue);

          await Future.delayed(TestDelays.delay * 1.5);
          tasks[3 * pool.maxConcurrency].cancel();
          expect(tasks[3 * pool.maxConcurrency].isCanceled, isTrue);

          await Future.wait(futures);

          expect(tasks.where((t) => t.isCanceled).length, equals(2));
          expect(tasks.where((t) => t.isRunning), isEmpty);
          expect(tasks.where((t) => t.isFinished).length,
              equals(3 * pool.maxConcurrency - 1));

          expect(errors, equals(2));
          expect(digits.length, isPositive);
          expect(digits.length + errors, equals(3 * pool.maxConcurrency + 1));
        });
      });

      tc.group('- StreamTask', () {
        tc.test('- immediate with pool.cancel()', () async {
          final digits = <int>[];
          final errors = <Exception>[];

          final futures = <Future>[];

          for (var i = 0; i < 2 * pool.maxConcurrency + 1; i++) {
            final done = Completer();
            futures.add(done.future);
            final task = pool.finiteTask(100);
            task.stream.listen(
              digits.add,
              onError: errors.add,
              onDone: done.complete,
            );
          }
          pool.cancel(null, 'Immediate cancelation');

          await Future.wait(futures);

          expect(digits, isEmpty);
          expect(errors.length, equals(2 * pool.maxConcurrency + 1));
          expect(errors.whereType<CanceledException>().length,
              equals(2 * pool.maxConcurrency + 1));
          expect(
              errors.whereType<CanceledException>().every((e) =>
                  e.message.toLowerCase().contains('immediate cancelation')),
              isTrue);
        });

        tc.test('- immediate with pool.cancel(task)', () async {
          final digits = <int>[];
          final errors = <Exception>[];

          final done = Completer();

          final task = pool.finiteTask(100);
          task.stream.listen(
            digits.add,
            onError: errors.add,
            onDone: done.complete,
          );
          pool.cancel(task, 'Immediate cancelation');

          await done.future;

          expect(digits, isEmpty);
          expect(errors.length, equals(1));
          expect(errors[0], isA<CanceledException>());
          expect((errors[0] as CanceledException).message,
              equals('Immediate cancelation'));
        });

        tc.test('- immediate with task.cancel()', () async {
          final digits = <int>[];
          final errors = <Exception>[];

          final done = Completer();

          final task = pool.finiteTask(100);
          task.stream.listen(
            digits.add,
            onError: errors.add,
            onDone: done.complete,
          );
          task.cancel('Immediate cancelation');

          await done.future;

          expect(digits, isEmpty);
          expect(errors.length, equals(1));
          expect(errors[0], isA<CanceledException>());
          lowerCaseCheck((errors[0] as CanceledException).message,
              contains('immediate cancelation'));
        });

        tc.test('- with pool.cancel()', () async {
          final results = <int, List>{};

          final tasks = <Future>[];
          for (var i = 0; i < 2 * pool.maxConcurrency + 1; i++) {
            final completer = Completer();
            tasks.add(completer.future);
            pool.finite(2 * i + 1).listen(
                  (results[i] ??= []).add,
                  onError: (results[i] ??= []).add,
                  onDone: completer.complete,
                );
          }

          expect(tasks.length, equals(2 * pool.maxConcurrency + 1));
          expect(
              results,
              equals(
                Map<int, List>.fromIterables(
                  Iterable.generate(tasks.length),
                  Iterable.generate(tasks.length, (_) => []),
                ),
              ));

          await Future.delayed(TestDelays.shortDelay * 5);
          pool.cancel();

          await Future.wait(tasks);

          // all streams have been executed or canceled
          expect(results.length, equals(tasks.length));

          final fullExecution =
              results.values.where((r) => r.every((e) => e is int)).length;
          final partialExecution = results.values
              .where((r) =>
                  r.any((e) => e is int) &&
                  r.any((e) => e is CanceledException))
              .length;
          final fullCancelation = results.values
              .where((r) => r.every((e) => e is CanceledException))
              .length;
          final severalErrors = results.values
              .where((r) => r.whereType<CanceledException>().length > 1)
              .length;

          expect(fullExecution, isPositive, reason: 'full exec');
          expect(partialExecution, isPositive, reason: 'partial');
          expect(fullCancelation, isPositive, reason: 'full cancel');
          expect(severalErrors, isZero, reason: 'multiple errors');
          expect(fullExecution + partialExecution + fullCancelation,
              equals(tasks.length));
        });

        tc.test('- with pool.cancel(task)', () async {
          final status = <int, String>{};
          int errors = 0;

          final tasks = <StreamTask>[];
          final started = <Future>[];
          final futures = <Future>[];
          for (var i = 0; i < 2 * pool.maxConcurrency + 1; i++) {
            final task = pool.finiteTask((i + 1) * 2);
            tasks.add(task);
            final start = Completer();
            started.add(start.future);
            final completer = Completer();
            futures.add(completer.future);
            status[i] = 'not started';
            task.stream.listen((event) {
              status[i] = 'started';
              if (!start.isCompleted) {
                start.complete();
              }
            }, onError: (e) {
              status[i] = (status[i] == 'started') ? 'interrupted' : 'canceled';
              errors += 1;
            }, onDone: () {
              if (status[i] == 'started') status[i] = 'completed';
              completer.complete();
            });
          }

          await started[0];
          pool.cancel(tasks[0]);
          expect(tasks[0].isCanceled, isTrue);

          await Future.delayed(TestDelays.delay * 2);
          pool.cancel(tasks[2 * pool.maxConcurrency]); // will be canceled
          expect(tasks[2 * pool.maxConcurrency].isCanceled, isTrue);

          await Future.wait(futures);

          expect(tasks.where((t) => t.isCanceled).length, equals(2));
          expect(tasks.where((t) => t.isRunning), isEmpty);
          expect(tasks.where((t) => t.isFinished).length,
              equals(2 * pool.maxConcurrency - 1));

          expect(errors, equals(2));
          expect(status.values.where((s) => s == 'started'), isEmpty);
          expect(
              status.values.where((s) => s == 'interrupted').length, equals(1));
          expect(status.values.where((s) => s == 'canceled').length, equals(1));
          expect(status.values.where((s) => s == 'completed').length,
              equals(2 * pool.maxConcurrency + 1 - errors));
        });

        tc.test('- with task.cancel()', () async {
          final status = <int, String>{};
          final firstTaskStarted = Completer();
          int errors = 0;

          final tasks = <StreamTask>[];
          final futures = <Future>[];
          for (var i = 0; i < 2 * pool.maxConcurrency + 1; i++) {
            final task = pool.finiteTask(i + 2);
            tasks.add(task);
            final completer = Completer();
            futures.add(completer.future);
            status[i] = 'not started';
            task.stream.listen((event) {
              status[i] = 'started';
              if (i == 0) {
                firstTaskStarted.complete();
              }
            }, onError: (e) {
              status[i] = (status[i] == 'started') ? 'interrupted' : 'canceled';
              errors += 1;
            }, onDone: () {
              if (status[i] == 'started') status[i] = 'completed';
              if (!completer.isCompleted) {
                completer.complete();
              }
            });
          }

          await firstTaskStarted.future;
          tasks[0].cancel();
          expect(tasks[0].isCanceled, isTrue);

          await Future.delayed(TestDelays.delay * 2.5);
          tasks[2 * pool.maxConcurrency].cancel();
          expect(tasks[2 * pool.maxConcurrency].isCanceled, isTrue);

          await Future.wait(futures);

          expect(tasks.where((t) => t.isCanceled).length, equals(2));
          expect(tasks.where((t) => t.isRunning), isEmpty);
          expect(tasks.where((t) => t.isFinished).length,
              equals(2 * pool.maxConcurrency - 1));

          expect(errors, equals(2));
          expect(status.values.where((s) => s == 'started'), isEmpty);
          expect(
              status.values.where((s) => s == 'interrupted').length, equals(1));
          expect(status.values.where((s) => s == 'canceled').length, equals(1));
          expect(status.values.where((s) => s == 'completed').length,
              equals(2 * pool.maxConcurrency + 1 - errors));
        });
      });

      tc.group('- CancelationToken', () {
        tc.test('- finite() worker', () async {
          final digits = <int>[];
          int count = 0;

          final N = 20;

          final cancelation = CancelableToken();
          final timer = Timer(TestDelays.shortDelay * N, cancelation.cancel);

          expect(cancelation.isCanceled, isFalse);

          try {
            await for (final n in worker.finite(50 * N, cancelation)) {
              digits.add(n);
              count++;
            }
            throw unexpectedSuccess('finite()');
          } on CanceledException catch (_) {
            // expected exception
          }

          timer.cancel();

          expect(cancelation.isCanceled, isTrue);
          expect(count, isPositive);
          expect(count, lessThanOrEqualTo(N));
          expect(digits, equals(Iterable.generate(count)));
        });

        tc.test('- infinite() worker', () async {
          final digits = <int>[];
          int count = 0;

          final N = 20;

          final cancelation = CancelableToken();
          final timer = Timer(TestDelays.shortDelay * N, cancelation.cancel);

          try {
            await for (final n in worker.infinite(cancelation)) {
              digits.add(n);
              count++;
            }
            throw unexpectedSuccess('infinite()');
          } on CanceledException catch (_) {
            // expected exception
          }

          timer.cancel();

          expect(cancelation.isCanceled, isTrue);
          expect(count, isPositive);
          expect(count, lessThanOrEqualTo(N));
          expect(digits, equals(Iterable.generate(count)));
        });

        tc.test('- finite() pool', () async {
          final L = 20;

          final cancelation = CancelableToken();
          Future.delayed(TestDelays.shortDelay * L * 1.8, cancelation.cancel);

          int success = 0;
          int errors = 0;

          final tasks = <Future<List<int>>>[];
          for (var i = 0; i < 2 * pool.maxConcurrency + 1; i++) {
            tasks.add(pool.finite(L, cancelation).toList().then((list) {
              success++;
              return list;
            }).onError((ex, st) {
              errors++;
              return []; /* swallow errors */
            }));
          }

          expect(success, isZero);
          expect(errors, isZero);

          await Future.delayed(TestDelays.delay);

          expect(pool.pendingWorkload, isPositive);

          await Future.wait(tasks);

          expect(pool.pendingWorkload, isZero);
          expect(cancelation.isCanceled, isTrue);
          expect(success, equals(pool.maxConcurrency));
          expect(success + errors, equals(tasks.length));

          pool.cancel();
        });
      });

      tc.group('- TimeoutToken', () {
        tc.test('- finite() worker', () async {
          final digits = <int>[];
          int count = 0;

          final N = 10;

          final timeout = TimeoutToken(TestDelays.shortDelay * N);

          try {
            await for (final n in worker.finite(50 * N, timeout)) {
              digits.add(n);
              count++;
            }
            throw unexpectedSuccess('finite()');
          } on TimeoutException catch (_) {
            // expected exception
          }

          expect(timeout.isCanceled, isTrue);
          expect(count, isPositive);
          expect(count, lessThanOrEqualTo(N));
          expect(digits, equals(Iterable.generate(count)));
        });

        tc.test('- infinite() worker', () async {
          final digits = <int>[];
          int count = 0;

          final N = 20;

          final timeout = TimeoutToken(TestDelays.shortDelay * N);

          try {
            await for (final n in worker.infinite(timeout)) {
              digits.add(n);
              count++;
            }
            throw unexpectedSuccess('infinite()');
          } on TimeoutException catch (_) {
            // expected exception
          }

          expect(count, isPositive);
          expect(count, lessThanOrEqualTo(N));
          expect(digits, equals(Iterable.generate(count)));
        });

        tc.test('- finite() pool', () async {
          final L = 20;

          final timeout = TimeoutToken(TestDelays.shortDelay * L * 1.8);

          int success = 0;
          int errors = 0;

          final tasks = <Future<List<int>>>[];
          for (var i = 0; i < 2 * pool.maxConcurrency + 1; i++) {
            tasks.add(pool.finite(L, timeout).toList().then((list) {
              success++;
              return list;
            }).onError((ex, st) {
              errors++;
              return []; /* swallow errors */
            }));
          }

          expect(success, isZero);
          expect(errors, isZero);

          await Future.delayed(TestDelays.delay);

          expect(pool.pendingWorkload, isPositive);

          await Future.wait(tasks);

          expect(timeout.isCanceled, isTrue);
          expect(success, equals(pool.maxConcurrency));
          expect(success + errors, equals(tasks.length));

          pool.cancel();
        });
      });

      tc.group('- CompositeToken', () {
        tc.test('- finite() worker', () async {
          final digits = <int>[];
          int count = 0;

          final N = 20;

          final timeout1 = TimeoutToken(TestDelays.shortDelay * N);
          final cancelation1 = CancelableToken();
          Timer(timeout1.timeout * 0.5, cancelation1.cancel);
          final composite1 = CompositeToken.any([timeout1, cancelation1]);

          try {
            await for (final n in worker.finite(50 * N, composite1)) {
              digits.add(n);
              count++;
            }
            throw unexpectedSuccess('finite()');
          } on CanceledException catch (_) {
            // expected exception
          }

          expect(composite1.isCanceled, isTrue);
          expect(timeout1.isCanceled, isFalse);
          expect(cancelation1.isCanceled, isTrue);
          expect(count, isPositive);
          expect(count, lessThanOrEqualTo(N));
          expect(digits, equals(Iterable.generate(count)));

          digits.clear();
          count = 0;

          final timeout2 = TimeoutToken(TestDelays.shortDelay * N);
          final cancelation2 = CancelableToken();
          final composite2 = CompositeToken.any([timeout2, cancelation2]);

          try {
            await for (final n in worker.finite(50 * N, composite2)) {
              digits.add(n);
              count++;
            }
            throw unexpectedSuccess('finite()');
          } on TimeoutException catch (_) {
            // expected exception
          }

          expect(composite2.isCanceled, isTrue);
          expect(timeout2.isCanceled, isTrue);
          expect(cancelation2.isCanceled, isFalse);
          expect(count, isPositive);
          expect(count, lessThanOrEqualTo(N));
          expect(digits, equals(Iterable.generate(count)));
        });

        tc.test('- infinite() worker', () async {
          final digits = <int>[];
          int count = 0;

          final N = 20;

          final timeout1 = TimeoutToken(TestDelays.shortDelay * N);
          final cancelation1 = CancelableToken();
          Timer(timeout1.timeout * 0.5, cancelation1.cancel);
          final composite1 = CompositeToken.any([timeout1, cancelation1]);

          try {
            await for (final n in worker.infinite(composite1)) {
              digits.add(n);
              count++;
            }
            throw unexpectedSuccess('infinite()');
          } on CanceledException catch (_) {
            // expected exception
          }

          expect(composite1.isCanceled, isTrue);
          expect(timeout1.isCanceled, isFalse);
          expect(cancelation1.isCanceled, isTrue);
          expect(count, isPositive);
          expect(count, lessThanOrEqualTo(N));
          expect(digits, equals(Iterable.generate(count)));

          digits.clear();
          count = 0;

          final timeout2 = TimeoutToken(TestDelays.shortDelay * N);
          final cancelation2 = CancelableToken();
          final composite2 = CompositeToken.any([timeout2, cancelation2]);

          try {
            await for (final n in worker.infinite(composite2)) {
              digits.add(n);
              count++;
            }
            throw unexpectedSuccess('infinite()');
          } on SquadronTimeoutException catch (_) {
            // expected exception
          }

          expect(count, isPositive);
          expect(count, lessThanOrEqualTo(N));
          expect(digits, equals(Iterable.generate(count)));
        });

        tc.test('- finite() pool', () async {
          final L = 20;

          final timeout1 = TimeoutToken(TestDelays.shortDelay * L * 1.8);
          final cancelation1 = CancelableToken();
          final composite1 = CompositeToken.any([timeout1, cancelation1]);

          int success = 0;
          int errors = 0;

          // launch 2 * pool.maxConcurrency + 1 tasks of length L ==> one task executes in ~ L * delay
          final tasks = <Future<List<int>>>[];
          for (var i = 0; i < 2 * pool.maxConcurrency + 1; i++) {
            tasks.add(pool.finite(L, composite1).toList().then((list) {
              success++;
              return list;
            }).onError((ex, st) {
              errors++;
              return []; /* swallow errors */
            }));
          }

          expect(success, isZero);
          expect(errors, isZero);

          await Future.delayed(TestDelays.delay);

          expect(pool.pendingWorkload, isPositive);

          // wait for completion
          await Future.wait(tasks);

          // timeout set to 1.8 * L * delay ==> only pool.maxConcurrency task should have completed
          expect(timeout1.isCanceled, isTrue);
          expect(cancelation1.isCanceled, isFalse);
          expect(success, equals(pool.maxConcurrency));
          expect(success + errors, equals(tasks.length));

          final timeout2 =
              TimeoutToken(TestDelays.shortDelay * 2 * pool.maxConcurrency * L);
          final token2 = CancelableToken();
          final composite2 = CompositeToken.any([timeout2, token2]);

          success = 0;
          errors = 0;

          // launch 2 * pool.maxConcurrency + 1 tasks of length L ==> one task executes in ~ L * delay
          tasks.clear();
          for (var i = 0; i < 2 * pool.maxConcurrency + 1; i++) {
            tasks.add(pool.finite(L, composite2).toList().then((list) {
              success++;
              return list;
            }).onError((ex, st) {
              errors++;
              return []; /* swallow errors */
            }));
          }

          expect(success, isZero);
          expect(errors, isZero);

          Timer(TestDelays.shortDelay * L * 1.8, token2.cancel);

          // wait for completion
          await Future.wait(tasks);

          // token2 was canceled after 1.8 * L * delay ==> only pool.maxConcurrency task should have completed
          expect(timeout2.isCanceled, isFalse);
          expect(token2.isCanceled, isTrue);
          expect(success, equals(pool.maxConcurrency));
          expect(success + errors, equals(tasks.length));

          pool.cancel();
        });
      });
    });
  });
}
