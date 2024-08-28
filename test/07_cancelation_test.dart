// ignore_for_file: file_names

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

void main() {
  TestContext.init('').then(execute);
  // TestContext.init('', TestPlatform.wasm).then(execute);
}

String testScript = '07_cancelation_test.dart';

void execute(TestContext? tc) {
  if (tc == null) return;

  tc.run(() {
    late TestWorkerPool pool;
    late TestWorker worker;

    setUpAll(() async {
      pool = TestWorkerPool(tc, concurrencySettings_222);
      worker = TestWorker(tc);
      await Future.wait([pool.start(), worker.start()].whereType<Future>());
    });

    tearDownAll(() {
      pool.stop();
      worker.stop();
    });

    tc.group("- Cancelation", () {
      tc.group('- ValueTask', () {
        tc.test('- immediate with pool.cancel()', () async {
          final count = 2 * pool.maxConcurrency + 1;
          final tasks = <Future>[], digits = <int>[];
          int errors = 0;
          for (var i = 0; i < count; i++) {
            tasks.add(pool.delayed(i).then(
                  digits.add,
                  onError: (_) => errors++,
                ));
          }

          // cancel all tasks
          pool.cancel();

          await Future.wait(tasks);
          expect(digits, isEmpty);
          expect(errors, count);
        });

        tc.test('- immediate with pool.cancel(task)', () async {
          final task1 = pool.delayedTask(3);
          final task2 = pool.delayedTask(3);

          // cancel task2
          pool.cancel(task2, 'Immediate cancelation');
          try {
            final value2 = await task2.value;
            throw unexpectedSuccess('delayedTask()', value2);
          } on CanceledException catch (ex) {
            expect(ex, reports('Immediate cancelation'));
          }

          // task1 completes
          expect(await task1.value, 3);
        });

        tc.test('- immediate with task.cancel()', () async {
          final task1 = pool.delayedTask(3);
          final task2 = pool.delayedTask(3);

          // cancel task2
          task2.cancel('Immediate cancelation');
          try {
            final value2 = await task2.value;
            throw unexpectedSuccess('delayedTask()', value2);
          } on CanceledException catch (ex) {
            expect(ex, reports('Immediate cancelation'));
          }

          // task1 completes
          expect(await task1.value, 3);
        });

        tc.test('- with pool.cancel()', () async {
          final count = 2 * pool.maxConcurrency + 1;
          final tasks = <Future>[], digits = <int>[];
          int errors = 0;
          for (var i = 0; i < count; i++) {
            tasks.add(
              pool.delayed(i).then(digits.add, onError: (e) => errors++),
            );
          }

          await Future.delayed(TestDelays.delay);
          pool.cancel();

          await Future.wait(tasks);
          expect(errors, isPositive);
          expect(digits, hasLength(count - errors));
        });

        tc.test('- with pool.cancel(task)', () async {
          final count = 3 * pool.maxConcurrency + 1;
          final tasks = <ValueTask>[], futures = <Future>[], digits = <int>[];
          int errors = 0;
          for (var i = 0; i < count; i++) {
            final task = pool.delayedTask(i);
            tasks.add(task);
            futures.add(task.value.then(digits.add, onError: (e) => errors++));
          }

          // immediate cancelation
          final firstTask = tasks.first;
          pool.cancel(firstTask);
          expect(firstTask.isCanceled, isTrue);
          expect(firstTask.isRunning, isFalse);
          expect(firstTask.isFinished, isFalse);

          await Future.delayed(TestDelays.delay * 1.5);

          // cancel last task
          final lastTask = tasks.last;
          pool.cancel(lastTask);
          expect(lastTask.isCanceled, isTrue);
          expect(lastTask.isRunning, isFalse);
          expect(lastTask.isFinished, isFalse);
          expect(lastTask.runningTime.inMicroseconds, isZero);

          await Future.wait(futures);

          expect(errors, 2);
          expect(digits, hasLength(count - errors));

          expect(tasks.where((t) => t.isRunning), isEmpty);
          expect(tasks.where((t) => t.isCanceled), hasLength(errors));
          expect(tasks.where((t) => t.isFinished), hasLength(count - errors));
        });

        tc.test('- with task.cancel()', () async {
          final count = 3 * pool.maxConcurrency + 1;
          final tasks = <ValueTask>[], futures = <Future>[], digits = <int>[];
          int errors = 0;
          for (var i = 0; i < count; i++) {
            final task = pool.delayedTask(i);
            tasks.add(task);
            futures.add(task.value.then(digits.add, onError: (e) => errors++));
          }

          // immediate cancelation
          final firstTask = tasks.first;
          firstTask.cancel();
          expect(firstTask.isCanceled, isTrue);
          expect(firstTask.isRunning, isFalse);
          expect(firstTask.isFinished, isFalse);

          await Future.delayed(TestDelays.delay * 1.5);

          // cancel last task
          final lastTask = tasks.last;
          lastTask.cancel();
          expect(lastTask.isCanceled, isTrue);
          expect(lastTask.isRunning, isFalse);
          expect(lastTask.isFinished, isFalse);
          expect(lastTask.runningTime.inMicroseconds, isZero);

          await Future.wait(futures);

          expect(errors, 2);
          expect(digits, hasLength(count - errors));

          expect(tasks.where((t) => t.isRunning), isEmpty);
          expect(tasks.where((t) => t.isCanceled), hasLength(errors));
          expect(tasks.where((t) => t.isFinished), hasLength(count - errors));
        });
      });

      tc.group('- StreamTask', () {
        tc.test('- immediate with pool.cancel()', () async {
          final count = 2 * pool.maxConcurrency + 1;
          final futures = <Future>[], digits = <int>[], errors = <Exception>[];
          for (var i = 0; i < count; i++) {
            final done = Completer();
            futures.add(done.future);
            pool
                .finiteTask(100)
                .stream
                .listen(digits.add, onError: errors.add, onDone: done.complete);
          }

          pool.cancel(null, 'Immediate cancelation');

          await Future.wait(futures);

          expect(digits, isEmpty);
          expect(errors, hasLength(count));
          expect(errors, everyElement(isA<CanceledException>()));
          expect(errors, everyElement(reports('Immediate cancelation')));
        });

        tc.test('- immediate with pool.cancel(task)', () async {
          final digits = <int>[], errors = <Exception>[];

          final task = pool.finiteTask(100);
          task.stream.listen(digits.add, onError: errors.add);
          pool.cancel(task, 'Immediate cancelation');

          await task.done;

          expect(digits, isEmpty);
          expect(errors, hasLength(1));
          expect(errors.first, isA<CanceledException>());
          expect(errors.first, reports('Immediate cancelation'));
        });

        tc.test('- immediate with task.cancel()', () async {
          final digits = <int>[], errors = <Exception>[];

          final task = pool.finiteTask(100);
          task.stream.listen(digits.add, onError: errors.add);
          task.cancel('Immediate cancelation');

          await task.done;

          expect(digits, isEmpty);
          expect(errors, hasLength(1));
          expect(errors.first, isA<CanceledException>());
          expect(errors.first, reports('Immediate cancelation'));
        });

        tc.test('- with pool.cancel()', () async {
          final count = 2 * pool.maxConcurrency + 1;
          final results = <List>[], tasks = <Future>[];
          for (var i = 0; i < count; i++) {
            final completer = Completer(), res = [];
            results.add(res);
            tasks.add(completer.future);
            pool
                .finite(2 * i + 1)
                .listen(res.add, onError: res.add, onDone: completer.complete);
          }

          await Future.delayed(TestDelays.delay);
          pool.cancel();

          await Future.wait(tasks);

          // all streams have been executed or canceled
          final fullExecutions =
              results.where((r) => r.every((e) => e is int)).length;
          final partialExecutions = results
              .where((r) =>
                  r.any((e) => e is int) &&
                  r.any((e) => e is CanceledException))
              .length;
          final fullCancelations = results
              .where((r) => r.every((e) => e is CanceledException))
              .length;
          final multipleErrors = results
              .where((r) => r.whereType<CanceledException>().length > 1)
              .length;

          expect(fullExecutions, isPositive);
          expect(partialExecutions, isPositive);
          expect(fullCancelations, isPositive);
          expect(multipleErrors, isZero);
          expect(fullExecutions + partialExecutions + fullCancelations, count);
        });

        tc.test('- with pool.cancel(task)', () async {
          final count = 2 * pool.maxConcurrency + 1;
          final tasks = <StreamTask>[], started = <Future>[];
          final status = List.filled(count, 'not started');
          int errors = 0;
          for (var i = 0; i < count; i++) {
            final start = Completer();
            started.add(start.future);
            final task = pool.finiteTask((i + 1) * 2);
            tasks.add(task);
            task.stream.listen((event) {
              if (!start.isCompleted) {
                start.complete();
                status[i] = 'started';
              }
            }, onError: (e) {
              status[i] = (status[i] == 'started') ? 'interrupted' : 'canceled';
              errors += 1;
            }, onDone: () {
              if (status[i] == 'started') status[i] = 'completed';
            });
          }

          expect(status.where((s) => s == 'started'), isEmpty);

          await started.first;
          pool.cancel(tasks.first);
          expect(tasks.first.isCanceled, isTrue);

          await Future.delayed(TestDelays.delay * 2);
          pool.cancel(tasks.last); // will be canceled
          expect(tasks.last.isCanceled, isTrue);

          expect(status.where((s) => s == 'started'), hasLength(isPositive));

          await Future.wait(tasks.map((t) => t.done));

          expect(tasks.where((t) => t.isRunning), isEmpty);
          expect(tasks.where((t) => t.isCanceled), hasLength(2));
          expect(tasks.where((t) => t.isFinished), hasLength(count - 2));

          expect(errors, 2);
          expect(status.where((s) => s == 'started'), isEmpty);
          expect(status.where((s) => s == 'interrupted'), hasLength(1));
          expect(status.where((s) => s == 'canceled'), hasLength(1));
          expect(status.where((s) => s == 'completed'), hasLength(count - 2));
        });

        tc.test('- with task.cancel()', () async {
          final count = 2 * pool.maxConcurrency + 1;
          final tasks = <StreamTask>[], started = <Future>[];
          final status = List.filled(count, 'not started');
          int errors = 0;
          for (var i = 0; i < count; i++) {
            final task = pool.finiteTask((i + 1) * 2);
            tasks.add(task);
            final start = Completer();
            started.add(start.future);
            task.stream.listen((event) {
              if (!start.isCompleted) {
                start.complete();
                status[i] = 'started';
              }
            }, onError: (e) {
              status[i] = (status[i] == 'started') ? 'interrupted' : 'canceled';
              errors += 1;
            }, onDone: () {
              if (status[i] == 'started') status[i] = 'completed';
            });
          }

          expect(status.where((s) => s == 'started'), isEmpty);

          await started.first;
          tasks.first.cancel();
          expect(tasks.first.isCanceled, isTrue);

          await Future.delayed(TestDelays.delay * 2);
          tasks.last.cancel(); // will be canceled
          expect(tasks.last.isCanceled, isTrue);

          expect(status.where((s) => s == 'started'), hasLength(isPositive));

          await Future.wait(tasks.map((t) => t.done));

          expect(tasks.where((t) => t.isRunning), isEmpty);
          expect(tasks.where((t) => t.isCanceled), hasLength(2));
          expect(tasks.where((t) => t.isFinished), hasLength(count - 2));

          expect(errors, 2);
          expect(status.where((s) => s == 'started'), isEmpty);
          expect(status.where((s) => s == 'interrupted'), hasLength(1));
          expect(status.where((s) => s == 'canceled'), hasLength(1));
          expect(status.where((s) => s == 'completed'), hasLength(count - 2));
        });
      });

      Future<({List<int> digits, Object? exception})> testFiniteCancelation(
          int N, CancelationToken token) async {
        Object? exception;
        final digits = <int>[];
        try {
          await for (final n in worker.finite(50 * N, token)) {
            digits.add(n);
          }
        } catch (ex) {
          exception = ex;
        }

        return (digits: digits, exception: exception);
      }

      Future<({List<int> digits, Object? exception})> testInfiniteCancelation(
          CancelationToken token) async {
        Object? exception;
        final digits = <int>[];
        try {
          await for (final n in worker.infinite(token)) {
            digits.add(n);
          }
        } catch (ex) {
          exception = ex;
        }
        return (digits: digits, exception: exception);
      }

      Future<({int success, int errors})> testFinitePoolCancelation(
          int N, int count, CancelationToken token) async {
        final tasks = <Future>[];
        int success = 0, errors = 0;
        for (var i = 0; i < count; i++) {
          tasks.add(pool.finite(N, token).toList().then(
                (list) => success++,
                onError: (_) => errors++,
              ));
        }

        expect(success, isZero);
        expect(errors, isZero);

        await Future.delayed(TestDelays.delay);

        expect(pool.pendingWorkload, isPositive);

        await Future.wait(tasks);

        return (success: success, errors: errors);
      }

      Future<({int success, int errors})> testInfinitePoolCancelation(
          int count, CancelationToken token) async {
        final tasks = <Future>[];
        int success = 0, errors = 0;
        for (var i = 0; i < count; i++) {
          tasks.add(pool.infinite(token).toList().then(
                (list) => success++,
                onError: (_) => errors++,
              ));
        }

        expect(success, isZero);
        expect(errors, isZero);

        await Future.delayed(TestDelays.delay);
        expect(pool.pendingWorkload, isPositive);

        await Future.wait(tasks);

        return (success: success, errors: errors);
      }

      tc.group('- CancelationToken', () {
        tc.test('- finite() worker', () async {
          final N = 20, cancelation = CancelableToken();

          // cancel the token after some time
          Timer(TestDelays.shortDelay * N, cancelation.cancel);
          expect(cancelation.isCanceled, isFalse);

          final res = await testFiniteCancelation(N, cancelation);
          expect(cancelation.isCanceled, isTrue);
          expect(res.exception, isA<CanceledException>());
          expect(res.digits, isNotEmpty);
          expect(res.digits, Iterable.generate(res.digits.length));
        });

        tc.test('- infinite() worker', () async {
          final N = 20, cancelation = CancelableToken();

          // cancel the token after some time
          Timer(TestDelays.shortDelay * N, cancelation.cancel);
          expect(cancelation.isCanceled, isFalse);

          final res = await testInfiniteCancelation(cancelation);
          expect(cancelation.isCanceled, isTrue);
          expect(res.exception, isA<CanceledException>());
          expect(res.digits, isNotEmpty);
          expect(res.digits, Iterable.generate(res.digits.length));
        });

        tc.test('- finite() pool', () async {
          final N = 20, count = 2 * pool.maxConcurrency + 1;

          // cancel the token after some time
          final cancelation = CancelableToken();
          Timer(TestDelays.shortDelay * N * 1.8, cancelation.cancel);

          final res = await testFinitePoolCancelation(N, count, cancelation);

          expect(cancelation.isCanceled, isTrue);
          expect(pool.pendingWorkload, isZero);
          expect(res.success, pool.maxConcurrency);
          expect(res.errors, count - res.success);
        });

        tc.test('- infinite() pool', () async {
          final count = 2 * pool.maxConcurrency + 1, N = 20;

          // cancel the token after some time
          final cancelation = CancelableToken();
          Timer(TestDelays.shortDelay * N * 1.8, cancelation.cancel);

          final res = await testInfinitePoolCancelation(count, cancelation);

          expect(cancelation.isCanceled, isTrue);
          expect(pool.pendingWorkload, isZero);
          expect(res.success, 0);
          expect(res.errors, count);
        });
      });

      tc.group('- TimeoutToken', () {
        tc.test('- finite() worker', () async {
          final N = 20, timeout = TimeoutToken(TestDelays.shortDelay * N);
          expect(timeout.isCanceled, isFalse);

          final res = await testFiniteCancelation(N, timeout);
          expect(timeout.isCanceled, isTrue);
          expect(res.exception, isA<TimeoutException>());
          expect(res.digits, isNotEmpty);
          expect(res.digits, Iterable.generate(res.digits.length));
        });

        tc.test('- infinite() worker', () async {
          final N = 20, timeout = TimeoutToken(TestDelays.shortDelay * N);
          expect(timeout.isCanceled, isFalse);

          final res = await testInfiniteCancelation(timeout);
          expect(timeout.isCanceled, isTrue);
          expect(res.exception, isA<TimeoutException>());
          expect(res.digits, isNotEmpty);
          expect(res.digits, Iterable.generate(res.digits.length));
        });

        tc.test('- finite() pool', () async {
          final count = 2 * pool.maxConcurrency + 1, N = 20;

          final timeout = TimeoutToken(TestDelays.shortDelay * N * 1.8);

          final res = await testFinitePoolCancelation(N, count, timeout);
          expect(timeout.isCanceled, isTrue);
          expect(pool.pendingWorkload, isZero);
          expect(res.success, pool.maxConcurrency);
          expect(res.errors, count - res.success);
        });

        tc.test('- infinite() pool', () async {
          final count = 2 * pool.maxConcurrency + 1, N = 20;

          final timeout = TimeoutToken(TestDelays.shortDelay * N * 1.8);

          final res = await testInfinitePoolCancelation(count, timeout);
          expect(timeout.isCanceled, isTrue);
          expect(pool.pendingWorkload, isZero);
          expect(res.success, 0);
          expect(res.errors, count);
        });
      });

      tc.group('- CompositeToken', () {
        tc.test('- finite() worker', () async {
          final N = 20;

          // canceled by cancelation1
          final timeout1 = TimeoutToken(TestDelays.shortDelay * N);
          final cancelation1 = CancelableToken();
          Timer(timeout1.timeout * 0.5, cancelation1.cancel);
          final composite1 = CompositeToken.any([timeout1, cancelation1]);
          expect(composite1.isCanceled, isFalse);

          var res = await testFiniteCancelation(N, composite1);
          expect(composite1.isCanceled, isTrue);
          expect(timeout1.isCanceled, isFalse);
          expect(cancelation1.isCanceled, isTrue);
          expect(res.exception, isA<CanceledException>());
          expect(res.digits, isNotEmpty);
          expect(res.digits, Iterable.generate(res.digits.length));

          // canceled by timeout2
          final timeout2 = TimeoutToken(TestDelays.shortDelay * N);
          final cancelation2 = CancelableToken();
          Timer(timeout2.timeout * 2, cancelation2.cancel);
          final composite2 = CompositeToken.any([timeout2, cancelation2]);
          expect(composite2.isCanceled, isFalse);

          res = await testFiniteCancelation(N, composite2);
          expect(composite2.isCanceled, isTrue);
          expect(timeout2.isCanceled, isTrue);
          expect(cancelation2.isCanceled, isFalse);
          expect(res.exception, isA<TimeoutException>());
          expect(res.digits, isNotEmpty);
          expect(res.digits, Iterable.generate(res.digits.length));

          // canceled by timeout3 and cancelation3
          final timeout3 = TimeoutToken(TestDelays.shortDelay * N);
          final cancelation3 = CancelableToken();
          Timer(timeout3.timeout * 0.5, cancelation3.cancel);
          final composite3 = CompositeToken.all([timeout3, cancelation3]);
          expect(composite3.isCanceled, isFalse);

          res = await testFiniteCancelation(N, composite3);
          expect(composite3.isCanceled, isTrue);
          expect(timeout3.isCanceled, isTrue);
          expect(cancelation3.isCanceled, isTrue);
          expect(res.exception, isA<CanceledExceptions>());
          expect(res.digits, isNotEmpty);
          expect(res.digits, Iterable.generate(res.digits.length));
        });

        tc.test('- infinite() worker', () async {
          final N = 20;

          // canceled by cancelation1
          final timeout1 = TimeoutToken(TestDelays.shortDelay * N);
          final cancelation1 = CancelableToken();
          Timer(timeout1.timeout * 0.5, cancelation1.cancel);
          final composite1 = CompositeToken.any([timeout1, cancelation1]);
          expect(composite1.isCanceled, isFalse);

          var res = await testInfiniteCancelation(composite1);
          expect(composite1.isCanceled, isTrue);
          expect(timeout1.isCanceled, isFalse);
          expect(cancelation1.isCanceled, isTrue);
          expect(res.exception, isA<CanceledException>());
          expect(res.digits, isNotEmpty);
          expect(res.digits, Iterable.generate(res.digits.length));

          // canceled by timeout2
          final timeout2 = TimeoutToken(TestDelays.shortDelay * N);
          final cancelation2 = CancelableToken();
          Timer(timeout2.timeout * 2, cancelation2.cancel);
          final composite2 = CompositeToken.any([timeout2, cancelation2]);
          expect(composite2.isCanceled, isFalse);

          res = await testInfiniteCancelation(composite2);
          expect(composite2.isCanceled, isTrue);
          expect(timeout2.isCanceled, isTrue);
          expect(cancelation2.isCanceled, isFalse);
          expect(res.exception, isA<TimeoutException>());
          expect(res.digits, isNotEmpty);
          expect(res.digits, Iterable.generate(res.digits.length));

          // canceled by timeout3 and cancelation3
          final timeout3 = TimeoutToken(TestDelays.shortDelay * N);
          final cancelation3 = CancelableToken();
          Timer(timeout3.timeout * 0.5, cancelation3.cancel);
          final composite3 = CompositeToken.all([timeout3, cancelation3]);
          expect(composite3.isCanceled, isFalse);

          res = await testInfiniteCancelation(composite3);
          expect(composite3.isCanceled, isTrue);
          expect(timeout3.isCanceled, isTrue);
          expect(cancelation3.isCanceled, isTrue);
          expect(res.exception, isA<CanceledExceptions>());
          expect(res.digits, isNotEmpty);
          expect(res.digits, Iterable.generate(res.digits.length));
        });

        tc.test('- finite() pool', () async {
          final count = 2 * pool.maxConcurrency + 1, N = 20;

          // canceled by cancelation1
          final timeout1 = TimeoutToken(TestDelays.shortDelay * N * 1.8);
          final cancelation1 = CancelableToken();
          Timer(timeout1.timeout * 0.5, cancelation1.cancel);
          final composite1 = CompositeToken.any([timeout1, cancelation1]);
          expect(composite1.isCanceled, isFalse);

          var res = await testFinitePoolCancelation(N, count, composite1);
          expect(composite1.isCanceled, isTrue);
          expect(timeout1.isCanceled, isFalse);
          expect(cancelation1.isCanceled, isTrue);
          expect(pool.pendingWorkload, isZero);
          expect(res.success, lessThanOrEqualTo(pool.maxConcurrency));
          expect(res.errors, count - res.success);

          // canceled by timeout2
          final timeout2 = TimeoutToken(TestDelays.shortDelay * N * 1.8);
          final cancelation2 = CancelableToken();
          Timer(timeout2.timeout * 2, cancelation2.cancel);
          final composite2 = CompositeToken.any([timeout2, cancelation2]);
          expect(composite2.isCanceled, isFalse);

          res = await testFinitePoolCancelation(N, count, composite2);
          expect(composite2.isCanceled, isTrue);
          expect(timeout2.isCanceled, isTrue);
          expect(cancelation2.isCanceled, isFalse);
          expect(pool.pendingWorkload, isZero);
          expect(res.success, pool.maxConcurrency);
          expect(res.errors, count - res.success);

          // canceled by timeout3 and cancelation3
          final timeout3 = TimeoutToken(TestDelays.shortDelay * N * 1.8);
          final cancelation3 = CancelableToken();
          Timer(timeout3.timeout * 0.5, cancelation3.cancel);
          final composite3 = CompositeToken.all([timeout3, cancelation3]);
          expect(composite3.isCanceled, isFalse);

          res = await testFinitePoolCancelation(N, count, composite3);
          expect(composite3.isCanceled, isTrue);
          expect(timeout3.isCanceled, isTrue);
          expect(cancelation3.isCanceled, isTrue);
          expect(pool.pendingWorkload, isZero);
          expect(res.success, pool.maxConcurrency);
          expect(res.errors, count - res.success);
        });

        tc.test('- infinite() pool', () async {
          final count = 2 * pool.maxConcurrency + 1, N = 20;

          // canceled by cancelation1
          final timeout1 = TimeoutToken(TestDelays.shortDelay * N);
          final cancelation1 = CancelableToken();
          Timer(timeout1.timeout * 0.5, cancelation1.cancel);
          final composite1 = CompositeToken.any([timeout1, cancelation1]);
          expect(composite1.isCanceled, isFalse);

          var res = await testInfinitePoolCancelation(count, composite1);
          expect(composite1.isCanceled, isTrue);
          expect(timeout1.isCanceled, isFalse);
          expect(cancelation1.isCanceled, isTrue);
          expect(pool.pendingWorkload, isZero);
          expect(res.success, 0);
          expect(res.errors, count);

          // canceled by timeout2
          final timeout2 = TimeoutToken(TestDelays.shortDelay * N);
          final cancelation2 = CancelableToken();
          Timer(timeout2.timeout * 2, cancelation2.cancel);
          final composite2 = CompositeToken.any([timeout2, cancelation2]);
          expect(composite2.isCanceled, isFalse);

          res = await testInfinitePoolCancelation(count, composite2);
          expect(composite2.isCanceled, isTrue);
          expect(timeout2.isCanceled, isTrue);
          expect(cancelation2.isCanceled, isFalse);
          expect(pool.pendingWorkload, isZero);
          expect(res.success, 0);
          expect(res.errors, count);

          // canceled by timeout3 and cancelation3
          final timeout3 = TimeoutToken(TestDelays.shortDelay * N);
          final cancelation3 = CancelableToken();
          Timer(timeout3.timeout * 0.5, cancelation3.cancel);
          final composite3 = CompositeToken.all([timeout3, cancelation3]);
          expect(composite3.isCanceled, isFalse);

          res = await testInfinitePoolCancelation(count, composite3);
          expect(composite3.isCanceled, isTrue);
          expect(timeout3.isCanceled, isTrue);
          expect(cancelation3.isCanceled, isTrue);
          expect(pool.pendingWorkload, isZero);
          expect(res.success, 0);
          expect(res.errors, count);
        });
      });
    });
  });
}
