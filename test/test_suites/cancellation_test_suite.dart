import 'dart:async';

import 'package:test/test.dart';

import 'package:squadron/squadron.dart';

import '../worker_services/test_service.dart';
import '../worker_services/test_service_worker.dart';

const concurrencySettings_222 =
    ConcurrencySettings(minWorkers: 2, maxWorkers: 2, maxParallel: 2);

void cancellationTests() {
  setUp(() {
    // Squadron.logger = ConsoleSquadronLogger();
  });

  group('- ValueTask', () {
    test('- immediate with pool.cancel()', () async {
      final pool = TestWorkerPool(concurrencySettings_222);
      await pool.start();

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

      pool.stop();
    });

    test('- immediate with pool.cancel(task)', () async {
      final pool = TestWorkerPool(concurrencySettings_222);
      await pool.start();

      final task = pool.delayedIdentityTask(3);
      pool.cancel(task, 'Immediate cancellation');

      try {
        final value = await task.value;
        throw Exception('delayedIdentityTask() completed with value $value');
      } catch (ex) {
        expect(ex, isA<CancelledException>());
        expect((ex as CancelledException).message,
            equals('Immediate cancellation'));
      }

      pool.stop();
    });

    test('- immediate with task.cancel()', () async {
      final pool = TestWorkerPool(concurrencySettings_222);
      await pool.start();

      final task = pool.delayedIdentityTask(3);
      task.cancel('Immediate cancellation');

      try {
        final value = await task.value;
        throw Exception('delayedIdentityTask() completed with value $value');
      } catch (ex) {
        expect(ex, isA<CancelledException>());
        expect((ex as CancelledException).message,
            equals('Immediate cancellation'));
      }

      pool.stop();
    });

    test('- with pool.cancel()', () async {
      final pool = TestWorkerPool(concurrencySettings_222);
      await pool.start();

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

      await Future.delayed(TestService.delay * 1.9);
      pool.cancel();

      await Future.wait(tasks);

      expect(digits.length, isPositive);
      expect(errors, isPositive);
      expect(digits.length + errors, equals(2 * pool.maxConcurrency + 1));

      pool.stop();
    });

    test('- with pool.cancel(task)', () async {
      final pool = TestWorkerPool(concurrencySettings_222);
      await pool.start();

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
      expect(firstTask.isCancelled, isTrue);
      expect(firstTask.isRunning, isFalse);
      expect(firstTask.isFinished, isFalse);
      expect(firstTask.runningTime.inMicroseconds, isZero);

      await Future.delayed(TestService.delay * 1.8);
      final lastTask = tasks[3 * pool.maxConcurrency];
      pool.cancel(lastTask);
      expect(lastTask.isCancelled, isTrue);
      expect(lastTask.runningTime.inMicroseconds, isZero);

      await Future.wait(futures);

      final running = tasks.where((t) => t.isRunning);
      final cancelled = tasks.where((t) => t.isCancelled);
      final finished = tasks.where((t) => t.isFinished);

      expect(running, isEmpty);
      expect(cancelled.length, equals(2));
      expect(finished.length + cancelled.length, equals(tasks.length));

      expect(errors, equals(2));
      expect(digits.length + errors, equals(tasks.length));

      pool.stop();
    });

    test('- with task.cancel()', () async {
      final pool = TestWorkerPool(concurrencySettings_222);
      await pool.start();

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
      expect(tasks[0].isCancelled, isTrue);

      await Future.delayed(TestService.delay * 1.5);
      tasks[3 * pool.maxConcurrency].cancel();
      expect(tasks[3 * pool.maxConcurrency].isCancelled, isTrue);

      await Future.wait(futures);

      expect(tasks.where((t) => t.isCancelled).length, equals(2));
      expect(tasks.where((t) => t.isRunning), isEmpty);
      expect(tasks.where((t) => t.isFinished).length,
          equals(3 * pool.maxConcurrency - 1));

      expect(errors, equals(2));
      expect(digits.length, isPositive);
      expect(digits.length + errors, equals(3 * pool.maxConcurrency + 1));

      pool.stop();
    });
  });

  group('- StreamTask', () {
    test('- immediate with pool.cancel()', () async {
      final pool = TestWorkerPool(concurrencySettings_222);
      await pool.start();

      final digits = <int>[];
      final errors = <Exception>[];

      final futures = <Future>[];

      for (var i = 0; i < 2 * pool.maxConcurrency + 1; i++) {
        final done = Completer();
        futures.add(done.future);
        final task = pool.finiteTask(100);
        task.stream.listen((n) => digits.add(n),
            onError: (ex) => errors.add(ex), onDone: () => done.complete());
      }
      pool.cancel(null, 'Immediate cancellation');

      await Future.wait(futures);

      expect(digits, isEmpty);
      expect(errors.length, equals(2 * pool.maxConcurrency + 1));
      expect(errors.whereType<CancelledException>().length,
          equals(2 * pool.maxConcurrency + 1));
      expect(
          errors.whereType<CancelledException>().map((e) => e.message).toSet(),
          equals(['Immediate cancellation']));

      pool.stop();
    });

    test('- immediate with pool.cancel(task)', () async {
      final pool = TestWorkerPool(concurrencySettings_222);
      await pool.start();

      final digits = <int>[];
      final errors = <Exception>[];

      final done = Completer();

      final task = pool.finiteTask(100);
      task.stream.listen((n) => digits.add(n),
          onError: (ex) => errors.add(ex), onDone: () => done.complete());
      pool.cancel(task, 'Immediate cancellation');

      await done.future;

      expect(digits, isEmpty);
      expect(errors.length, equals(1));
      expect(errors[0], isA<CancelledException>());
      expect((errors[0] as CancelledException).message,
          equals('Immediate cancellation'));

      pool.stop();
    });

    test('- immediate with task.cancel()', () async {
      final pool = TestWorkerPool(concurrencySettings_222);
      await pool.start();

      final digits = <int>[];
      final errors = <Exception>[];

      final done = Completer();

      final task = pool.finiteTask(100);
      task.stream.listen((n) => digits.add(n),
          onError: (ex) => errors.add(ex), onDone: () => done.complete());
      task.cancel('Immediate cancellation');

      await done.future;

      expect(digits, isEmpty);
      expect(errors.length, equals(1));
      expect(errors[0], isA<CancelledException>());
      expect((errors[0] as CancelledException).message,
          equals('Immediate cancellation'));

      pool.stop();
    });

    test('- with pool.cancel()', () async {
      final pool = TestWorkerPool(concurrencySettings_222);
      await pool.start();

      final results = <int, List<dynamic>>{};

      final tasks = <Future>[];
      for (var i = 0; i < 2 * pool.maxConcurrency + 1; i++) {
        final completer = Completer();
        tasks.add(completer.future);
        pool.finite(i + 1).listen((value) {
          final res = (results[i] ??= []);
          res.add(value);
        }, onError: (error) {
          final res = (results[i] ??= []);
          res.add(error);
        }, onDone: () {
          completer.complete();
        });
      }

      expect(tasks.length, equals(2 * pool.maxConcurrency + 1));
      expect(results, isEmpty);

      await Future.delayed(TestService.delay * 5);
      pool.cancel();

      await Future.wait(tasks);

      // all streams have been executed or cancelled
      expect(results.length, equals(tasks.length));

      final fullExecution =
          results.values.where((r) => r.every((e) => e is int)).length;
      final partialExecution = results.values
          .where((r) =>
              r.any((e) => e is int) && r.any((e) => e is CancelledException))
          .length;
      final fullCancellation = results.values
          .where((r) => r.every((e) => e is CancelledException))
          .length;
      final severalErrors = results.values
          .where((r) => r.whereType<CancelledException>().length > 1)
          .length;

      expect(fullExecution, isPositive);
      expect(partialExecution, isPositive);
      expect(fullCancellation, isPositive);
      expect(severalErrors, isZero);
      expect(fullExecution + partialExecution + fullCancellation,
          equals(tasks.length));

      pool.stop();
    });

    test('- with pool.cancel(task)', () async {
      final pool = TestWorkerPool(concurrencySettings_222);
      await pool.start();

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
          status[i] = (status[i] == 'started') ? 'interrupted' : 'cancelled';
          errors += 1;
        }, onDone: () {
          if (status[i] == 'started') status[i] = 'completed';
          completer.complete();
        });
      }

      await started[0];
      pool.cancel(tasks[0]);
      expect(tasks[0].isCancelled, isTrue);

      await Future.delayed(TestService.delay * 2);
      pool.cancel(tasks[2 * pool.maxConcurrency]); // will be cancelled
      expect(tasks[2 * pool.maxConcurrency].isCancelled, isTrue);

      await Future.wait(futures);

      expect(tasks.where((t) => t.isCancelled).length, equals(2));
      expect(tasks.where((t) => t.isRunning), isEmpty);
      expect(tasks.where((t) => t.isFinished).length,
          equals(2 * pool.maxConcurrency - 1));

      expect(errors, equals(2));
      expect(status.values.where((s) => s == 'started'), isEmpty);
      expect(status.values.where((s) => s == 'interrupted').length, equals(1));
      expect(status.values.where((s) => s == 'cancelled').length, equals(1));
      expect(status.values.where((s) => s == 'completed').length,
          equals(2 * pool.maxConcurrency + 1 - errors));

      pool.stop();
    });

    test('- with task.cancel()', () async {
      final pool = TestWorkerPool(concurrencySettings_222);
      await pool.start();

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
          status[i] = (status[i] == 'started') ? 'interrupted' : 'cancelled';
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
      expect(tasks[0].isCancelled, isTrue);

      await Future.delayed(TestService.delay * 2.5);
      tasks[2 * pool.maxConcurrency].cancel();
      expect(tasks[2 * pool.maxConcurrency].isCancelled, isTrue);

      await Future.wait(futures);

      expect(tasks.where((t) => t.isCancelled).length, equals(2));
      expect(tasks.where((t) => t.isRunning), isEmpty);
      expect(tasks.where((t) => t.isFinished).length,
          equals(2 * pool.maxConcurrency - 1));

      expect(errors, equals(2));
      expect(status.values.where((s) => s == 'started'), isEmpty);
      expect(status.values.where((s) => s == 'interrupted').length, equals(1));
      expect(status.values.where((s) => s == 'cancelled').length, equals(1));
      expect(status.values.where((s) => s == 'completed').length,
          equals(2 * pool.maxConcurrency + 1 - errors));

      pool.stop();
    });
  });

  group('- CancellationToken', () {
    test('- gets cancelled', () async {
      final cancellation = CancellationToken();

      await Future.delayed(Duration(milliseconds: 5));
      expect(cancellation.cancelled, isFalse);

      cancellation.cancel();

      expect(cancellation.cancelled, isTrue);
    });

    test('- notifies listeners', () async {
      final cancellation = CancellationToken();

      bool notified = false;
      cancellation.addListener(() => notified = true);

      cancellation.cancel();

      expect(cancellation.cancelled, isTrue);
      expect(notified, isTrue);
    });

    test('- notifies listeners when already cancelled', () async {
      final cancellation = CancellationToken();

      bool notified = false;
      void listener() => notified = true;

      cancellation.cancel();
      expect(cancellation.cancelled, isTrue);
      expect(notified, isFalse);

      cancellation.addListener(listener);
      expect(cancellation.cancelled, isTrue);
      expect(notified, isTrue);
    });

    test('- finite() worker', () async {
      final worker = TestWorker();

      final digits = <int>[];
      int count = 0;

      final N = 20;

      final cancellation = CancellationToken();
      Timer(TestService.delay * N, cancellation.cancel);

      expect(cancellation.cancelled, isFalse);

      try {
        await for (final n in worker.finite(50 * N, cancellation)) {
          digits.add(n);
          count++;
        }
        // should never happen
        throw Exception('finite() completed successfully');
      } catch (e) {
        expect(e, isA<CancelledException>());
      }

      expect(cancellation.cancelled, isTrue);
      expect(count, isPositive);
      expect(count, lessThanOrEqualTo(N));
      expect(digits, equals(Iterable.generate(count)));

      worker.stop();
    });

    test('- infinite() worker', () async {
      final worker = TestWorker();

      final digits = <int>[];
      int count = 0;

      final N = 20;

      final cancellation = CancellationToken();
      Timer(TestService.delay * N, cancellation.cancel);

      try {
        await for (final n in worker.infinite(cancellation)) {
          digits.add(n);
          count++;
        }
        // should never happen
        throw Exception('infinite() completed sucessfully');
      } on CancelledException catch (ex) {
        expect(ex, isA<CancelledException>());
      }

      expect(cancellation.cancelled, isTrue);
      expect(count, isPositive);
      expect(count, lessThanOrEqualTo(N));
      expect(digits, equals(Iterable.generate(count)));
    });

    test('- finite() pool', () async {
      final pool = TestWorkerPool(concurrencySettings_222);
      await pool.start();

      final L = 20;

      final cancellation = CancellationToken();
      Future.delayed(TestService.delay * L * 1.5, cancellation.cancel);

      int success = 0;
      int errors = 0;

      final tasks = <Future>[];
      for (var i = 0; i < 2 * pool.maxConcurrency + 1; i++) {
        tasks.add(pool.finite(L, cancellation).toList().then((list) {
          success++;
          return list;
        }).onError((ex, st) {
          errors++;
          return []; /* swallow errors */
        }));
      }

      expect(success, isZero);
      expect(errors, isZero);

      await Future.delayed(TestService.delay);

      expect(pool.pendingWorkload, isPositive);

      await Future.wait(tasks);

      expect(pool.pendingWorkload, isZero);
      expect(cancellation.cancelled, isTrue);
      expect(success, equals(pool.maxConcurrency));
      expect(success + errors, equals(tasks.length));

      pool.cancel();
      pool.stop();
    });
  });

  group('- TimeOutToken', () {
    test('- is not programmatically cancellable', () async {
      final timeout = TimeOutToken(TestService.shortDelay);
      expect(() => timeout.cancel(), throwsA(isA<SquadronError>()));
      expect(timeout.cancelled, isFalse);
    });

    test('- gets cancelled after specified duration', () async {
      final timeout = TimeOutToken(TestService.shortDelay);
      timeout.ensureStarted();

      await Future.delayed(timeout.duration * 0.6);
      expect(timeout.cancelled, isFalse);

      await Future.delayed(timeout.duration * 0.6);
      expect(timeout.cancelled, isTrue);
    });

    test('- notifies listeners', () async {
      final timeout = TimeOutToken(TestService.shortDelay);
      timeout.ensureStarted();

      bool notified = false;
      void listener() => notified = true;

      timeout.addListener(listener);

      await Future.delayed(timeout.duration * 0.6);

      expect(timeout.cancelled, isFalse);
      expect(notified, isFalse);

      await Future.delayed(timeout.duration * 0.6);

      expect(timeout.cancelled, isTrue);
      expect(notified, isTrue);
    });

    test('- notifies listeners when already cancelled', () async {
      final timeout = TimeOutToken(TestService.shortDelay);
      timeout.ensureStarted();

      bool notified = false;
      void listener() => notified = true;

      expect(timeout.cancelled, isFalse);
      expect(notified, isFalse);

      await Future.delayed(timeout.duration * 0.6);

      expect(timeout.cancelled, isFalse);
      expect(notified, isFalse);

      await Future.delayed(timeout.duration * 0.6);

      expect(timeout.cancelled, isTrue);
      expect(notified, isFalse);

      timeout.addListener(listener);

      expect(timeout.cancelled, isTrue);
      expect(notified, isTrue);
    });

    test('- finite() worker', () async {
      final worker = TestWorker();

      final digits = <int>[];
      int count = 0;

      final N = 10;

      final timeout = TimeOutToken(TestService.delay * N);

      try {
        await for (final n in worker.finite(50 * N, timeout)) {
          digits.add(n);
          count++;
        }
        // should never happen
        throw Exception('finite() completed successfully');
      } catch (ex) {
        expect(ex, isA<TaskTimeoutException>());
      }

      expect(timeout.cancelled, isTrue);
      expect(count, isPositive);
      expect(count, lessThanOrEqualTo(N));
      expect(digits, equals(Iterable.generate(count)));

      worker.stop();
    });

    test('- infinite() worker', () async {
      final worker = TestWorker();

      final digits = <int>[];
      int count = 0;

      final N = 20;

      final timeout = TimeOutToken(TestService.delay * N);

      try {
        await for (final n in worker.infinite(timeout)) {
          digits.add(n);
          count++;
        }
        // should never happen
        throw Exception('infinite() completed successfully');
      } catch (ex) {
        expect(ex, isA<TaskTimeoutException>());
      }

      expect(count, isPositive);
      expect(count, lessThanOrEqualTo(N));
      expect(digits, equals(Iterable.generate(count)));

      worker.stop();
    });

    test('- finite() pool', () async {
      final pool = TestWorkerPool(concurrencySettings_222);
      await pool.start();

      final L = 10;

      final timeout = TimeOutToken(TestService.delay * L * 1.75);

      int success = 0;
      int errors = 0;

      final tasks = <Future>[];
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

      await Future.wait(tasks);

      expect(timeout.cancelled, isTrue);
      expect(success, equals(pool.maxConcurrency));
      expect(success + errors, equals(tasks.length));

      pool.cancel();
      pool.stop();
    });
  });

  group('- CompositeToken', () {
    test('- is not programmatically cancellable', () async {
      final cancellation = CancellationToken();
      final composite = CompositeToken([cancellation], CompositeMode.any);
      expect(() => composite.cancel(), throwsA(isA<SquadronError>()));
    });

    test('- gets cancelled in CompositeMode.any', () async {
      final cancellation1 = CancellationToken();
      final cancellation2 = CancellationToken();
      final composite =
          CompositeToken([cancellation1, cancellation2], CompositeMode.any);

      expect(composite.cancelled, isFalse);
      cancellation1.cancel();
      expect(composite.cancelled, isTrue);
    });

    test('- gets cancelled in CompositeMode.all', () async {
      final cancellation1 = CancellationToken();
      final cancellation2 = CancellationToken();
      final composite =
          CompositeToken([cancellation1, cancellation2], CompositeMode.all);

      expect(composite.cancelled, isFalse);
      cancellation1.cancel();
      expect(composite.cancelled, isFalse);
      cancellation2.cancel();
      expect(composite.cancelled, isTrue);
    });

    test('- gets cancelled by TimeOutToken', () async {
      final timeout = TimeOutToken(TestService.shortDelay);
      final cancellation = CancellationToken();
      final composite =
          CompositeToken([cancellation, timeout], CompositeMode.any);
      composite.ensureStarted();

      expect(timeout.cancelled, isFalse);
      expect(cancellation.cancelled, isFalse);
      expect(composite.cancelled, isFalse);

      await Future.delayed(timeout.duration * 0.6);

      expect(timeout.cancelled, isFalse);
      expect(cancellation.cancelled, isFalse);
      expect(composite.cancelled, isFalse);

      await Future.delayed(timeout.duration * 0.9);

      expect(timeout.cancelled, isTrue);
      expect(cancellation.cancelled, isFalse);
      expect(composite.cancelled, isTrue);
    });

    test('- notifies listeners', () async {
      final cancellation1 = CancellationToken();
      final cancellation2 = CancellationToken();
      final composite =
          CompositeToken([cancellation1, cancellation2], CompositeMode.all);

      bool notified = false;
      composite.addListener(() => notified = true);

      expect(composite.cancelled, isFalse);
      expect(notified, isFalse);

      cancellation1.cancel();
      expect(composite.cancelled, isFalse);
      expect(notified, isFalse);

      cancellation2.cancel();
      expect(composite.cancelled, isTrue);
      expect(notified, isTrue);
    });

    test('- notifies listeners when already cancelled', () async {
      final cancellation = CancellationToken('token #1');
      final timeout = TimeOutToken(TestService.shortDelay, 'token #2');
      timeout.ensureStarted();

      int notified = 0;
      void listener() => notified++;

      cancellation.cancel();

      expect(cancellation.cancelled, isTrue);
      expect(timeout.cancelled, isFalse);

      await Future.delayed(timeout.duration);

      expect(cancellation.cancelled, isTrue);
      expect(timeout.cancelled, isTrue);

      final composite =
          CompositeToken([cancellation, timeout], CompositeMode.all);

      expect(composite.cancelled, isTrue);
      expect(notified, isZero);

      composite.addListener(listener);
      expect(notified, equals(1));
    });

    test('- finite() worker', () async {
      final worker = TestWorker();

      final digits = <int>[];
      int count = 0;

      final N = 20;

      final timeout1 = TimeOutToken(TestService.delay * N);
      final cancellation1 = CancellationToken();
      Timer(timeout1.duration * 0.5, cancellation1.cancel);
      final composite1 =
          CompositeToken([timeout1, cancellation1], CompositeMode.any);

      expect(timeout1.started, isFalse);

      try {
        await for (final n in worker.finite(50 * N, composite1)) {
          expect(timeout1.started, isTrue);
          digits.add(n);
          count++;
        }
        // should never happen
        throw Exception('finite() completed successfully');
      } catch (ex) {
        expect(ex, isA<CancelledException>());
      }

      expect(composite1.cancelled, isTrue);
      expect(timeout1.cancelled, isFalse);
      expect(cancellation1.cancelled, isTrue);
      expect(count, isPositive);
      expect(count, lessThanOrEqualTo(N));
      expect(digits, equals(Iterable.generate(count)));

      digits.clear();
      count = 0;

      final timeout2 = TimeOutToken(TestService.delay * N);
      final cancellation2 = CancellationToken();
      final composite2 =
          CompositeToken([timeout2, cancellation2], CompositeMode.any);

      expect(timeout2.started, isFalse);

      try {
        await for (final n in worker.finite(50 * N, composite2)) {
          expect(timeout2.started, isTrue);
          digits.add(n);
          count++;
        }
        // should never happen
        throw Exception('finite() completed successfully');
      } catch (ex) {
        expect(ex, isA<TaskTimeoutException>());
      }

      expect(composite2.cancelled, isTrue);
      expect(timeout2.cancelled, isTrue);
      expect(cancellation2.cancelled, isFalse);
      expect(count, isPositive);
      expect(count, lessThanOrEqualTo(N));
      expect(digits, equals(Iterable.generate(count)));

      worker.stop();
    });

    test('- infinite() worker', () async {
      final worker = TestWorker();

      final digits = <int>[];
      int count = 0;

      final N = 20;

      final timeout1 = TimeOutToken(TestService.delay * N);
      final cancellation1 = CancellationToken();
      Timer(timeout1.duration * 0.5, cancellation1.cancel);
      final composite1 =
          CompositeToken([timeout1, cancellation1], CompositeMode.any);

      expect(timeout1.started, isFalse);

      try {
        await for (final n in worker.infinite(composite1)) {
          expect(timeout1.started, isTrue);
          digits.add(n);
          count++;
        }
        // should never happen
        throw Exception('infinite() completed successfully');
      } catch (ex) {
        expect(ex, isA<CancelledException>());
      }

      expect(composite1.cancelled, isTrue);
      expect(timeout1.cancelled, isFalse);
      expect(cancellation1.cancelled, isTrue);
      expect(count, isPositive);
      expect(count, lessThanOrEqualTo(N));
      expect(digits, equals(Iterable.generate(count)));

      digits.clear();
      count = 0;

      final timeout2 = TimeOutToken(TestService.delay * N);
      final cancellation2 = CancellationToken();
      final composite2 =
          CompositeToken([timeout2, cancellation2], CompositeMode.any);

      try {
        await for (final n in worker.infinite(composite2)) {
          digits.add(n);
          count++;
        }
        // should never happen
        throw Exception('infinite() completed successfully');
      } catch (ex) {
        expect(ex, isA<TaskTimeoutException>());
      }

      expect(count, isPositive);
      expect(count, lessThanOrEqualTo(N));
      expect(digits, equals(Iterable.generate(count)));

      worker.stop();
    });

    test('- finite() pool', () async {
      final pool = TestWorkerPool(concurrencySettings_222);
      await pool.start();

      final L = 20;

      final timeout1 = TimeOutToken(TestService.delay * L * 1.5);
      final cancellation1 = CancellationToken();
      final composite1 =
          CompositeToken([timeout1, cancellation1], CompositeMode.any);

      int success = 0;
      int errors = 0;

      // launch 2 * pool.maxConcurrency + 1 tasks of length L ==> one task executes in ~ L * delay
      final tasks = <Future>[];
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

      // wait for completion
      await Future.wait(tasks);

      // timeout set to 1.5 * L * delay ==> only pool.maxConcurrency task should have completed
      expect(timeout1.cancelled, isTrue);
      expect(cancellation1.cancelled, isFalse);
      expect(success, equals(pool.maxConcurrency));
      expect(success + errors, equals(tasks.length));

      final timeout2 =
          TimeOutToken(TestService.delay * 2 * pool.maxConcurrency * L);
      final token2 = CancellationToken();
      final composite2 = CompositeToken([timeout2, token2], CompositeMode.any);

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

      Timer(TestService.delay * L * 1.5, token2.cancel);

      // wait for completion
      await Future.wait(tasks);

      // token2 was cancelled after 1.5 * L * delay ==> only pool.maxConcurrency task should have completed
      expect(timeout2.cancelled, isFalse);
      expect(token2.cancelled, isTrue);
      expect(success, equals(pool.maxConcurrency));
      expect(success + errors, equals(tasks.length));

      pool.cancel();
      pool.stop();
    });
  });
}
