// ignore_for_file: file_names

import 'dart:async';

import 'package:cancelation_token/cancelation_token.dart';
import 'package:squadron/squadron.dart';
import 'package:test/test.dart';
import 'package:using/using.dart';

import 'src/test_context.dart';
import 'src/utils.dart';
import 'test_constants.dart';
import 'test_extensions.dart';
import 'worker_services/test_service_worker.dart';

Future<void> main() => TestContext.run(execute);

const testScript = '08_cancelation_test.dart';

void execute(TestContext? tc) {
  if (tc == null) return;

  tc.launch(() {
    tc.group('- CANCELATION', () {
      tc.group('- ValueTask', () {
        tc.test('- Immediate with pool.cancel()', () async {
          await TestWorkerPool(tc, concurrency_222).useAsync((p) async {
            final count = 2 * p.maxConcurrency + 1;
            final tasks = <Future>[], digits = <int>[];
            int errors = 0;
            for (var i = 0; i < count; i++) {
              tasks.add(p.delayed(i).then(
                    digits.add,
                    onError: (_) => errors++,
                  ));
            }

            // cancel all tasks
            p.cancelAll();

            await Future.wait(tasks);
            expect(digits, isEmpty);
            expect(errors, count);
          });
        });

        tc.test('- Immediate with pool.cancel(task)', () async {
          await TestWorkerPool(tc, concurrency_222).useAsync((p) async {
            final task1 = p.delayedTask(3);
            final task2 = p.delayedTask(3);

            // cancel task2
            p.cancel(task2, 'Immediate cancelation');
            try {
              final value2 = await task2.value;
              throw unexpectedSuccess('delayedTask()', value2);
            } on CanceledException catch (ex) {
              expect(ex, reports('Immediate cancelation'));
            }

            // task1 completes
            expect(await task1.value, 3);
          });
        });

        tc.test('- Immediate with task.cancel()', () async {
          await TestWorkerPool(tc, concurrency_222).useAsync((p) async {
            final task1 = p.delayedTask(3);
            final task2 = p.delayedTask(3);

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
        });

        tc.test('- With pool.cancel()', () async {
          await TestWorkerPool(tc, concurrency_222).useAsync((p) async {
            final count = 2 * p.maxConcurrency + 1;
            final tasks = <Future>[], digits = <int>[];
            int errors = 0;
            for (var i = 0; i < count; i++) {
              tasks.add(
                p.delayed(i).then(digits.add, onError: (e) => errors++),
              );
            }

            await Future.delayed(delay_80ms);
            p.cancelAll();

            await Future.wait(tasks);
            expect(errors, isPositive);
            expect(digits, hasLength(count - errors));
          });
        });

        tc.test('- With pool.cancel(task)', () async {
          await TestWorkerPool(tc, concurrency_222).useAsync((p) async {
            final count = 3 * p.maxConcurrency + 1;
            final tasks = <ValueTask>[], futures = <Future>[], digits = <int>[];
            int errors = 0;
            for (var i = 0; i < count; i++) {
              final task = p.delayedTask(i);
              tasks.add(task);
              futures
                  .add(task.value.then(digits.add, onError: (_) => errors++));
            }

            // immediate cancelation
            final firstTask = tasks.first;
            p.cancel(firstTask);
            expect(firstTask.isCanceled, isTrue);
            expect(firstTask.isRunning, isFalse);
            expect(firstTask.isFinished, isFalse);

            await Future.delayed(delay_80ms * 1.5);

            // cancel last task
            final lastTask = tasks.last;
            p.cancel(lastTask);
            expect(lastTask.isCanceled, isTrue);
            expect(lastTask.isRunning, isFalse);
            expect(lastTask.isFinished, isFalse);
            expect(lastTask.runningTime.inMicroseconds, isZero);

            await Future.wait(futures);

            expect(errors, 2);
            expect(digits, hasLength(count - errors));

            if (tasks.where((t) => t.isRunning).isNotEmpty) {
              // let Squadron finalize worker status management
              await Future.delayed(Duration.zero);
            }

            expect(tasks.where((t) => t.isRunning), isEmpty);
            expect(tasks.where((t) => t.isCanceled), hasLength(errors));
            expect(tasks.where((t) => t.isFinished), hasLength(count - errors));
          });
        });

        tc.test('- With task.cancel()', () async {
          await TestWorkerPool(tc, concurrency_222).useAsync((p) async {
            final count = 3 * p.maxConcurrency + 1;
            final tasks = <ValueTask>[], futures = <Future>[], digits = <int>[];
            int errors = 0;
            for (var i = 0; i < count; i++) {
              final task = p.delayedTask(i);
              tasks.add(task);
              futures
                  .add(task.value.then(digits.add, onError: (_) => errors++));
            }

            // immediate cancelation
            final firstTask = tasks.first;
            firstTask.cancel();
            expect(firstTask.isCanceled, isTrue);
            expect(firstTask.isRunning, isFalse);
            expect(firstTask.isFinished, isFalse);

            await Future.delayed(delay_80ms * 1.5);

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

            if (tasks.where((t) => t.isRunning).isNotEmpty) {
              // let Squadron finalize worker status management
              await Future.delayed(Duration.zero);
            }

            expect(tasks.where((t) => t.isRunning), isEmpty);
            expect(tasks.where((t) => t.isCanceled), hasLength(errors));
            expect(tasks.where((t) => t.isFinished), hasLength(count - errors));
          });
        });
      });

      tc.group('- StreamTask', () {
        tc.test('- Immediate with pool.cancel()', () async {
          await TestWorkerPool(tc, concurrency_222).useAsync((p) async {
            final count = 2 * p.maxConcurrency + 1;
            final futures = <Future>[],
                digits = <int>[],
                errors = <Exception>[];
            for (var i = 0; i < count; i++) {
              final done = Completer();
              futures.add(done.future);
              p.finiteTask(100).stream.listen(digits.add,
                  onError: errors.add, onDone: done.complete);
            }

            p.cancelAll('Immediate cancelation');

            await Future.wait(futures);

            expect(digits, isEmpty);
            expect(errors, hasLength(count));
            expect(errors, everyElement(isA<CanceledException>()));
            expect(errors, everyElement(reports('Immediate cancelation')));
          });
        });

        tc.test('- Immediate with pool.cancel(task)', () async {
          await TestWorkerPool(tc, concurrency_222).useAsync((p) async {
            final digits = <int>[], errors = <Exception>[];

            final task = p.finiteTask(100);
            task.stream.listen(digits.add, onError: errors.add);
            p.cancel(task, 'Immediate cancelation');

            await Future.delayed(delay_20ms);

            expect(digits, isEmpty);
            expect(errors, hasLength(1));
            expect(errors.first, isA<CanceledException>());
            expect(errors.first, reports('Immediate cancelation'));
          });
        });

        tc.test('- Immediate with task.cancel()', () async {
          await TestWorkerPool(tc, concurrency_222).useAsync((p) async {
            final digits = <int>[], errors = <Exception>[];

            final task = p.finiteTask(100);
            task.stream.listen(digits.add, onError: errors.add);
            task.cancel('Immediate cancelation');

            await Future.delayed(delay_20ms);

            expect(digits, isEmpty);
            expect(errors, hasLength(1));
            expect(errors.first, isA<CanceledException>());
            expect(errors.first, reports('Immediate cancelation'));
          });
        });

        tc.test('- With pool.cancelAll()', () async {
          await TestWorkerPool(tc, concurrency_222).useAsync((p) async {
            final count = 2 * p.maxConcurrency + 1;
            final results = <List>[], tasks = <Future>[];
            for (var i = 0; i < count; i++) {
              final completer = Completer(), res = [];
              results.add(res);
              tasks.add(completer.future);
              p.finite(2 * i + 1).listen(res.add,
                  onError: res.add, onDone: completer.complete);
            }

            await Future.delayed(delay_80ms * 2);
            p.cancelAll();

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
            expect(
                fullExecutions + partialExecutions + fullCancelations, count);
          });
        });

        tc.test('- With pool.cancel(task)', () async {
          await TestWorkerPool(tc, concurrency_222).useAsync((p) async {
            final count = 2 * p.maxConcurrency + 1;
            final tasks = <StreamTask>[], started = <Future>[];
            final status = List.filled(count, 'not started');
            int errors = 0;
            for (var i = 0; i < count; i++) {
              final start = Completer();
              started.add(start.future);
              final task = p.finiteTask((i + 1) * 2);
              tasks.add(task);
              task.stream.listen((event) {
                if (!start.isCompleted) {
                  start.complete();
                  status[i] = 'started';
                }
              }, onError: (e) {
                status[i] =
                    (status[i] == 'started') ? 'interrupted' : 'canceled';
                errors += 1;
              }, onDone: () {
                if (status[i] == 'started') status[i] = 'completed';
              });
            }

            expect(status.where((s) => s == 'started'), isEmpty);

            await started.first;
            p.cancel(tasks.first);
            expect(tasks.first.isCanceled, isTrue);

            await Future.delayed(delay_80ms * 2);
            p.cancel(tasks.last); // will be canceled
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

        tc.test('- With task.cancel()', () async {
          await TestWorkerPool(tc, concurrency_222).useAsync((p) async {
            final count = 2 * p.maxConcurrency + 1;
            final tasks = <StreamTask>[], started = <Future>[];
            final status = List.filled(count, 'not started');
            int errors = 0;
            for (var i = 0; i < count; i++) {
              final task = p.finiteTask((i + 1) * 2);
              tasks.add(task);
              final start = Completer();
              started.add(start.future);
              task.stream.listen((event) {
                if (!start.isCompleted) {
                  start.complete();
                  status[i] = 'started';
                }
              }, onError: (e) {
                status[i] =
                    (status[i] == 'started') ? 'interrupted' : 'canceled';
                errors += 1;
              }, onDone: () {
                if (status[i] == 'started') status[i] = 'completed';
              });
            }

            expect(status.where((s) => s == 'started'), isEmpty);

            await started.first;
            tasks.first.cancel();
            expect(tasks.first.isCanceled, isTrue);

            await Future.delayed(delay_80ms * 2);
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
      });

      tc.group('- CancelationToken', () {
        tc.test('- Finite() worker', () async {
          await TestWorker(tc).useAsync((w) async {
            final N = 20, cancelation = CancelableToken();

            // cancel the token after some time
            Timer(delay_20ms * N, cancelation.cancel);
            expect(cancelation.isCanceled, isFalse);

            final res = await _testFiniteCancelation(w, N, cancelation);
            expect(cancelation.isCanceled, isTrue);
            expect(res.exception, isA<CanceledException>());
            expect(res.digits, isNotEmpty);
            expect(res.digits, Iterable.generate(res.digits.length));
          });
        });

        tc.test('- Infinite() worker', () async {
          await TestWorker(tc).useAsync((w) async {
            final N = 20, cancelation = CancelableToken();

            // cancel the token after some time
            Timer(delay_20ms * N, cancelation.cancel);
            expect(cancelation.isCanceled, isFalse);

            final res = await _testInfiniteCancelation(w, cancelation);
            expect(cancelation.isCanceled, isTrue);
            expect(res.exception, isA<CanceledException>());
            expect(res.digits, isNotEmpty);
            expect(res.digits, Iterable.generate(res.digits.length));
          });
        });

        tc.test('- Finite() pool', () async {
          await TestWorkerPool(tc).useAsync((p) async {
            final N = 20, count = 2 * p.maxConcurrency + 1;

            // cancel the token after some time
            final token = CancelableToken();
            Timer(delay_20ms * N * 1.8, token.cancel);

            final res = await _testFinitePoolCancelation(p, N, count, token);

            expect(token.isCanceled, isTrue);
            expect(p.pendingWorkload, isZero);
            expect(res.success, lessThanOrEqualTo(p.maxConcurrency));
            expect(res.errors, count - res.success);
          });
        });

        tc.test('- Infinite() pool', () async {
          await TestWorkerPool(tc).useAsync((p) async {
            final count = 2 * p.maxConcurrency + 1, N = 20;

            // cancel the token after some time
            final token = CancelableToken();
            Timer(delay_20ms * N * 1.8, token.cancel);

            final res = await _testInfinitePoolCancelation(p, count, token);

            expect(token.isCanceled, isTrue);
            expect(p.pendingWorkload, isZero);
            expect(res.success, 0);
            expect(res.errors, count);
          });
        });
      });

      tc.group('- TimeoutToken', () {
        tc.test('- Finite() worker', () async {
          await TestWorker(tc).useAsync((w) async {
            final N = 20, timeout = TimeoutToken(delay_20ms * N);
            expect(timeout.isCanceled, isFalse);

            final res = await _testFiniteCancelation(w, N, timeout);
            expect(timeout.isCanceled, isTrue);
            expect(res.exception, isA<TimeoutException>());
            expect(res.digits, isNotEmpty);
            expect(res.digits, Iterable.generate(res.digits.length));
          });
        });

        tc.test('- Infinite() worker', () async {
          await TestWorker(tc).useAsync((w) async {
            final N = 20, timeout = TimeoutToken(delay_20ms * N);
            expect(timeout.isCanceled, isFalse);

            final res = await _testInfiniteCancelation(w, timeout);
            expect(timeout.isCanceled, isTrue);
            expect(res.exception, isA<TimeoutException>());
            expect(res.digits, isNotEmpty);
            expect(res.digits, Iterable.generate(res.digits.length));
          });
        });

        tc.test('- Finite() pool', () async {
          await TestWorkerPool(tc).useAsync((p) async {
            final count = 2 * p.maxConcurrency + 1, N = 20;

            final timeout = TimeoutToken(delay_20ms * N * 1.8);

            final res = await _testFinitePoolCancelation(p, N, count, timeout);
            expect(timeout.isCanceled, isTrue);
            expect(p.pendingWorkload, isZero);
            expect(res.success, lessThanOrEqualTo(p.maxConcurrency));
            expect(res.errors, count - res.success);
          });
        });

        tc.test('- Infinite() pool', () async {
          await TestWorkerPool(tc).useAsync((p) async {
            final count = 2 * p.maxConcurrency + 1, N = 20;

            final timeout = TimeoutToken(delay_20ms * N * 1.8);

            final res = await _testInfinitePoolCancelation(p, count, timeout);
            expect(timeout.isCanceled, isTrue);
            expect(p.pendingWorkload, isZero);
            expect(res.success, 0);
            expect(res.errors, count);
          });
        });
      });

      tc.group('- CompositeToken', () {
        tc.test('- Finite() worker', () async {
          await TestWorker(tc).useAsync((w) async {
            final N = 20;

            // canceled by cancelation1
            final timeout1 = TimeoutToken(delay_20ms * N);
            final cancelation1 = CancelableToken();
            Timer(timeout1.timeout * 0.5, cancelation1.cancel);
            final composite1 = CompositeToken.any([timeout1, cancelation1]);
            expect(composite1.isCanceled, isFalse);

            var res = await _testFiniteCancelation(w, N, composite1);
            expect(composite1.isCanceled, isTrue);
            expect(timeout1.isCanceled, isFalse);
            expect(cancelation1.isCanceled, isTrue);
            expect(res.exception, isA<CanceledException>());
            expect(res.digits, isNotEmpty);
            expect(res.digits, Iterable.generate(res.digits.length));

            // canceled by timeout2
            final timeout2 = TimeoutToken(delay_20ms * N);
            final cancelation2 = CancelableToken();
            Timer(timeout2.timeout * 2, cancelation2.cancel);
            final composite2 = CompositeToken.any([timeout2, cancelation2]);
            expect(composite2.isCanceled, isFalse);

            res = await _testFiniteCancelation(w, N, composite2);
            expect(composite2.isCanceled, isTrue);
            expect(timeout2.isCanceled, isTrue);
            expect(cancelation2.isCanceled, isFalse);
            expect(res.exception, isA<TimeoutException>());
            expect(res.digits, isNotEmpty);
            expect(res.digits, Iterable.generate(res.digits.length));

            // canceled by timeout3 and cancelation3
            final timeout3 = TimeoutToken(delay_20ms * N);
            final cancelation3 = CancelableToken();
            Timer(timeout3.timeout * 0.5, cancelation3.cancel);
            final composite3 = CompositeToken.all([timeout3, cancelation3]);
            expect(composite3.isCanceled, isFalse);

            res = await _testFiniteCancelation(w, N, composite3);
            expect(composite3.isCanceled, isTrue);
            expect(timeout3.isCanceled, isTrue);
            expect(cancelation3.isCanceled, isTrue);
            expect(res.exception, isA<CanceledExceptions>());
            expect(res.digits, isNotEmpty);
            expect(res.digits, Iterable.generate(res.digits.length));
          });
        });

        tc.test('- Infinite() worker', () async {
          await TestWorker(tc).useAsync((w) async {
            final N = 20;

            // canceled by cancelation1
            final timeout1 = TimeoutToken(delay_20ms * N);
            final cancelation1 = CancelableToken();
            Timer(timeout1.timeout * 0.5, cancelation1.cancel);
            final composite1 = CompositeToken.any([timeout1, cancelation1]);
            expect(composite1.isCanceled, isFalse);

            var res = await _testInfiniteCancelation(w, composite1);
            expect(composite1.isCanceled, isTrue);
            expect(timeout1.isCanceled, isFalse);
            expect(cancelation1.isCanceled, isTrue);
            expect(res.exception, isA<CanceledException>());
            expect(res.digits, isNotEmpty);
            expect(res.digits, Iterable.generate(res.digits.length));

            // canceled by timeout2
            final timeout2 = TimeoutToken(delay_20ms * N);
            final cancelation2 = CancelableToken();
            Timer(timeout2.timeout * 2, cancelation2.cancel);
            final composite2 = CompositeToken.any([timeout2, cancelation2]);
            expect(composite2.isCanceled, isFalse);

            res = await _testInfiniteCancelation(w, composite2);
            expect(composite2.isCanceled, isTrue);
            expect(timeout2.isCanceled, isTrue);
            expect(cancelation2.isCanceled, isFalse);
            expect(res.exception, isA<TimeoutException>());
            expect(res.digits, isNotEmpty);
            expect(res.digits, Iterable.generate(res.digits.length));

            // canceled by timeout3 and cancelation3
            final timeout3 = TimeoutToken(delay_20ms * N);
            final cancelation3 = CancelableToken();
            Timer(timeout3.timeout * 0.5, cancelation3.cancel);
            final composite3 = CompositeToken.all([timeout3, cancelation3]);
            expect(composite3.isCanceled, isFalse);

            res = await _testInfiniteCancelation(w, composite3);
            expect(composite3.isCanceled, isTrue);
            expect(timeout3.isCanceled, isTrue);
            expect(cancelation3.isCanceled, isTrue);
            expect(res.exception, isA<CanceledExceptions>());
            expect(res.digits, isNotEmpty);
            expect(res.digits, Iterable.generate(res.digits.length));
          });
        });

        tc.test('- Finite() pool', () async {
          await TestWorkerPool(tc).useAsync((p) async {
            final count = 2 * p.maxConcurrency + 1, N = 20;

            // canceled by cancelation1
            final timeout1 = TimeoutToken(delay_20ms * N * 1.8);
            final cancelation1 = CancelableToken();
            Timer(timeout1.timeout * 0.5, cancelation1.cancel);
            final composite1 = CompositeToken.any([timeout1, cancelation1]);
            expect(composite1.isCanceled, isFalse);

            var res = await _testFinitePoolCancelation(p, N, count, composite1);
            expect(composite1.isCanceled, isTrue);
            expect(timeout1.isCanceled, isFalse);
            expect(cancelation1.isCanceled, isTrue);
            expect(p.pendingWorkload, isZero);
            expect(res.success, lessThanOrEqualTo(p.maxConcurrency));
            expect(res.errors, count - res.success);

            // canceled by timeout2
            final timeout2 = TimeoutToken(delay_20ms * N * 1.8);
            final cancelation2 = CancelableToken();
            Timer(timeout2.timeout * 4, cancelation2.cancel);
            final composite2 = CompositeToken.any([timeout2, cancelation2]);
            expect(composite2.isCanceled, isFalse);

            res = await _testFinitePoolCancelation(p, N, count, composite2);
            expect(composite2.isCanceled, isTrue);
            expect(timeout2.isCanceled, isTrue);
            expect(cancelation2.isCanceled, isFalse);
            expect(p.pendingWorkload, isZero);
            expect(res.success, lessThanOrEqualTo(p.maxConcurrency));
            expect(res.errors, count - res.success);

            // canceled by timeout3 and cancelation3
            final timeout3 = TimeoutToken(delay_20ms * N * 1.8);
            final cancelation3 = CancelableToken();
            Timer(timeout3.timeout * 0.4, cancelation3.cancel);
            final composite3 = CompositeToken.all([timeout3, cancelation3]);
            expect(composite3.isCanceled, isFalse);

            res = await _testFinitePoolCancelation(p, N, count, composite3);
            expect(composite3.isCanceled, isTrue);
            expect(timeout3.isCanceled, isTrue);
            expect(cancelation3.isCanceled, isTrue);
            expect(p.pendingWorkload, isZero);
            expect(res.success, lessThanOrEqualTo(p.maxConcurrency));
            expect(res.errors, count - res.success);
          });
        });

        tc.test('- Infinite() pool', () async {
          await TestWorkerPool(tc).useAsync((p) async {
            final count = 2 * p.maxConcurrency + 1, N = 20;

            // canceled by cancelation1
            final timeout1 = TimeoutToken(delay_20ms * N);
            final cancelation1 = CancelableToken();
            Timer(timeout1.timeout * 0.5, cancelation1.cancel);
            final composite1 = CompositeToken.any([timeout1, cancelation1]);
            expect(composite1.isCanceled, isFalse);

            var res = await _testInfinitePoolCancelation(p, count, composite1);
            expect(composite1.isCanceled, isTrue);
            expect(timeout1.isCanceled, isFalse);
            expect(cancelation1.isCanceled, isTrue);
            expect(p.pendingWorkload, isZero);
            expect(res.success, 0);
            expect(res.errors, count);

            // canceled by timeout2
            final timeout2 = TimeoutToken(delay_20ms * N);
            final cancelation2 = CancelableToken();
            Timer(timeout2.timeout * 2, cancelation2.cancel);
            final composite2 = CompositeToken.any([timeout2, cancelation2]);
            expect(composite2.isCanceled, isFalse);

            res = await _testInfinitePoolCancelation(p, count, composite2);
            expect(composite2.isCanceled, isTrue);
            expect(timeout2.isCanceled, isTrue);
            expect(cancelation2.isCanceled, isFalse);
            expect(p.pendingWorkload, isZero);
            expect(res.success, 0);
            expect(res.errors, count);

            // canceled by timeout3 and cancelation3
            final timeout3 = TimeoutToken(delay_20ms * N);
            final cancelation3 = CancelableToken();
            Timer(timeout3.timeout * 0.5, cancelation3.cancel);
            final composite3 = CompositeToken.all([timeout3, cancelation3]);
            expect(composite3.isCanceled, isFalse);

            res = await _testInfinitePoolCancelation(p, count, composite3);
            expect(composite3.isCanceled, isTrue);
            expect(timeout3.isCanceled, isTrue);
            expect(cancelation3.isCanceled, isTrue);
            expect(p.pendingWorkload, isZero);
            expect(res.success, 0);
            expect(res.errors, count);
          });
        });
      });
    });
  });
}

Future<({List<int> digits, Object? exception})> _testFiniteCancelation(
    TestWorker worker, int N, CancelationToken token) async {
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

Future<({List<int> digits, Object? exception})> _testInfiniteCancelation(
    TestWorker worker, CancelationToken token) async {
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

Future<({int success, int errors})> _testFinitePoolCancelation(
    TestWorkerPool pool, int N, int count, CancelationToken token) async {
  final tasks = <Future>[];
  int success = 0, errors = 0;
  for (var i = 0; i < count; i++) {
    tasks.add(pool.finite(N, token).toList().then(
          (_) => success++,
          onError: (_) => errors++,
        ));
  }

  expect(success, isZero);
  expect(errors, isZero);

  await Future.delayed(delay_80ms);

  expect(pool.pendingWorkload, isPositive);

  await Future.wait(tasks);

  return (success: success, errors: errors);
}

Future<({int success, int errors})> _testInfinitePoolCancelation(
    TestWorkerPool pool, int count, CancelationToken token) async {
  final tasks = <Future>[];
  int success = 0, errors = 0;
  for (var i = 0; i < count; i++) {
    tasks.add(pool.infinite(token).toList().then(
          (_) => success++,
          onError: (_) => errors++,
        ));
  }

  expect(success, isZero);
  expect(errors, isZero);

  await Future.delayed(delay_80ms);
  expect(pool.pendingWorkload, isPositive);

  await Future.wait(tasks);

  return (success: success, errors: errors);
}
