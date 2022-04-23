import 'dart:async';

import 'package:test/test.dart';

import 'package:squadron/squadron.dart';

import '../worker_services/test_service.dart';
import '../worker_services/test_service_worker.dart';

const concurrencySettings_222 =
    ConcurrencySettings(minWorkers: 2, maxWorkers: 2, maxParallel: 2);

void cancellationTests() {
  test('- CompositeToken - referencing already cancelled tokens', () async {
    final token = CancellationToken('token #1');
    final timeoutToken = TimeOutToken(Duration(milliseconds: 5), 'token #2');
    timeoutToken.ensureStarted();

    int notified = 0;
    void listener() => notified++;

    token.cancel();

    expect(token.cancelled, isTrue);
    expect(timeoutToken.cancelled, isFalse);

    await Future.delayed(timeoutToken.duration);

    expect(token.cancelled, isTrue);
    expect(timeoutToken.cancelled, isTrue);

    final composite = CompositeToken([token, timeoutToken], CompositeMode.all);

    expect(composite.cancelled, isTrue);
    expect(notified, isZero);

    token.addListener(listener);
    expect(notified, equals(1));

    timeoutToken.addListener(listener);
    expect(notified, equals(2));

    composite.addListener(listener);

    expect(notified, equals(3));
  });

  test(
      '- value task cancellation - immediate cancellation - using pool.cancel()',
      () async {
    final pool = TestWorkerPool(concurrencySettings_222);

    final digits = <int>[];
    var errors = 0;

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

  test(
      '- value task cancellation - immediate cancellation - using pool.cancel(task)',
      () async {
    final pool = TestWorkerPool(concurrencySettings_222);

    final task = pool.delayedIdentityTask(3);
    pool.cancel(task, 'Immediate cancellation');

    try {
      final value = await task.value;
      throw Exception('delayedIdentityTask() completed with value $value');
    } catch (ex) {
      expect(ex, isA<CancelledException>());
      expect(
          (ex as CancelledException).message, equals('Immediate cancellation'));
    }

    pool.stop();
  });

  test(
      '- value task cancellation - immediate cancellation - using task.cancel()',
      () async {
    final pool = TestWorkerPool(concurrencySettings_222);

    final task = pool.delayedIdentityTask(3);
    task.cancel('Immediate cancellation');

    try {
      final value = await task.value;
      throw Exception('delayedIdentityTask() completed with value $value');
    } catch (ex) {
      expect(ex, isA<CancelledException>());
      expect(
          (ex as CancelledException).message, equals('Immediate cancellation'));
    }

    pool.stop();
  });

  test(
      '- stream task cancellation - immediate cancellation - using pool.cancel()',
      () async {
    final pool = TestWorkerPool(concurrencySettings_222);

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
    expect(errors.whereType<CancelledException>().map((e) => e.message).toSet(),
        equals(['Immediate cancellation']));

    pool.stop();
  });

  test(
      '- stream task cancellation - immediate cancellation - using pool.cancel(task)',
      () async {
    final pool = TestWorkerPool(concurrencySettings_222);

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

  test(
      '- stream task cancellation - immediate cancellation - using task.cancel()',
      () async {
    final pool = TestWorkerPool(concurrencySettings_222);

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

  test('- value task cancellation - using pool.cancel()', () async {
    final pool = TestWorkerPool(concurrencySettings_222);

    final digits = <int>[];
    var errors = 0;

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

  test('- stream task cancellation - using pool.cancel()', () async {
    final pool = TestWorkerPool(concurrencySettings_222);

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

  test('- specific value task cancellation - using pool.cancel(task)',
      () async {
    final pool = TestWorkerPool(concurrencySettings_222);

    final digits = <int>[];
    var errors = 0;

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

  test('- specific value task cancellation - using task.cancel()', () async {
    final pool = TestWorkerPool(concurrencySettings_222);

    final digits = <int>[];
    var errors = 0;

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

  test('- specific stream task cancellation - using pool.cancel(task)',
      () async {
    final pool = TestWorkerPool(concurrencySettings_222);
    await pool.start();

    final status = <int, String>{};
    var errors = 0;

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

    await Future.delayed(TestService.delay * 1.5);
    pool.cancel(tasks[0]);
    expect(tasks[0].isCancelled, isTrue);

    await Future.delayed(TestService.delay * 2.5);
    pool.cancel(tasks[2 * pool.maxConcurrency]);
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

  test('- specific stream task cancellation - using task.cancel()', () async {
    final pool = TestWorkerPool(concurrencySettings_222);
    await pool.start();

    final status = <int, String>{};
    var errors = 0;

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

    await Future.delayed(TestService.delay * 1.5);
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

  test('- cancellation token - gets cancelled', () async {
    final token = CancellationToken();

    await Future.delayed(Duration(milliseconds: 5));
    expect(token.cancelled, isFalse);

    token.cancel();

    expect(token.cancelled, isTrue);
  });

  test('- cancellation token - notifies listeners', () async {
    final token = CancellationToken();

    var notified = false;
    token.addListener(() => notified = true);

    token.cancel();

    expect(token.cancelled, isTrue);
    expect(notified, isTrue);
  });

  test('- cancellable token - notifies listeners when already cancelled',
      () async {
    final token = CancellationToken();

    var notified = false;
    void listener() => notified = true;

    token.cancel();
    expect(token.cancelled, isTrue);
    expect(notified, isFalse);

    token.addListener(listener);
    expect(token.cancelled, isTrue);
    expect(notified, isTrue);
  });

  test('- timeout token - is not programmatically cancellable', () async {
    final token = TimeOutToken(TestService.delay * 2);
    expect(() => token.cancel(), throwsA(isA<SquadronError>()));
  });

  test('- timeout token - gets cancelled after specified duration', () async {
    final timeoutToken = TimeOutToken(TestService.delay * 2);
    timeoutToken.ensureStarted();

    await Future.delayed(timeoutToken.duration * 0.5);
    expect(timeoutToken.cancelled, isFalse);

    await Future.delayed(timeoutToken.duration);
    expect(timeoutToken.cancelled, isTrue);
  });

  test('- timeout token - notifies listeners', () async {
    final timeoutToken = TimeOutToken(TestService.delay * 2);
    timeoutToken.ensureStarted();

    var notified = false;
    void listener() => notified = true;

    timeoutToken.addListener(listener);

    await Future.delayed(timeoutToken.duration * 0.5);

    expect(timeoutToken.cancelled, isFalse);
    expect(notified, isFalse);

    await Future.delayed(timeoutToken.duration);

    expect(timeoutToken.cancelled, isTrue);
    expect(notified, isTrue);
  });

  test('- timeout token - notifies listeners when already cancelled', () async {
    final timeoutToken = TimeOutToken(TestService.delay * 2);
    timeoutToken.ensureStarted();

    var notified = false;
    void listener() => notified = true;

    expect(timeoutToken.cancelled, isFalse);
    expect(notified, isFalse);

    await Future.delayed(timeoutToken.duration * 0.5);

    expect(timeoutToken.cancelled, isFalse);
    expect(notified, isFalse);

    await Future.delayed(timeoutToken.duration);

    expect(timeoutToken.cancelled, isTrue);
    expect(notified, isFalse);

    timeoutToken.addListener(listener);

    expect(timeoutToken.cancelled, isTrue);
    expect(notified, isTrue);
  });

  test('- composite token - is not programmatically cancellable', () async {
    final cancellable = CancellationToken();
    final token = CompositeToken([cancellable], CompositeMode.any);
    expect(() => token.cancel(), throwsA(isA<SquadronError>()));
  });

  test('- composite token - gets cancelled in CompositeMode.any', () async {
    final cancellable1 = CancellationToken();
    final cancellable2 = CancellationToken();
    final token =
        CompositeToken([cancellable1, cancellable2], CompositeMode.any);

    expect(token.cancelled, isFalse);
    cancellable1.cancel();
    expect(token.cancelled, isTrue);
  });

  test('- composite token - gets cancelled in CompositeMode.all', () async {
    final cancellable1 = CancellationToken();
    final cancellable2 = CancellationToken();
    final token =
        CompositeToken([cancellable1, cancellable2], CompositeMode.all);

    expect(token.cancelled, isFalse);
    cancellable1.cancel();
    expect(token.cancelled, isFalse);
    cancellable2.cancel();
    expect(token.cancelled, isTrue);
  });

  test('- composite token - gets cancelled by timeout token', () async {
    final timeoutToken = TimeOutToken(Duration(milliseconds: 5));
    final cancellableToken = CancellationToken();
    final token =
        CompositeToken([cancellableToken, timeoutToken], CompositeMode.any);
    token.ensureStarted();

    expect(timeoutToken.cancelled, isFalse);
    expect(cancellableToken.cancelled, isFalse);
    expect(token.cancelled, isFalse);

    await Future.delayed(timeoutToken.duration * 0.6);

    expect(timeoutToken.cancelled, isFalse);
    expect(cancellableToken.cancelled, isFalse);
    expect(token.cancelled, isFalse);

    await Future.delayed(timeoutToken.duration * 0.6);

    expect(timeoutToken.cancelled, isTrue);
    expect(cancellableToken.cancelled, isFalse);
    expect(token.cancelled, isTrue);
  });

  test('- composite token - notifies listeners', () async {
    final cancellable1 = CancellationToken();
    final cancellable2 = CancellationToken();
    final token =
        CompositeToken([cancellable1, cancellable2], CompositeMode.all);

    var notified = false;
    token.addListener(() => notified = true);

    expect(token.cancelled, isFalse);
    expect(notified, isFalse);

    cancellable1.cancel();
    expect(token.cancelled, isFalse);
    expect(notified, isFalse);

    cancellable2.cancel();
    expect(token.cancelled, isTrue);
    expect(notified, isTrue);
  });

  test('- CompositeToken - notified listeners when already cancelled',
      () async {
    final token = CancellationToken('token #1');
    final timeoutToken = TimeOutToken(TestService.delay, 'token #2');
    timeoutToken.ensureStarted();

    int notified = 0;
    void listener() => notified++;

    token.cancel();

    expect(token.cancelled, isTrue);
    expect(timeoutToken.cancelled, isFalse);

    await Future.delayed(timeoutToken.duration);

    expect(token.cancelled, isTrue);
    expect(timeoutToken.cancelled, isTrue);

    final composite = CompositeToken([token, timeoutToken], CompositeMode.all);

    expect(composite.cancelled, isTrue);
    expect(notified, isZero);

    token.addListener(listener);
    expect(notified, equals(1));

    timeoutToken.addListener(listener);
    expect(notified, equals(2));

    composite.addListener(listener);

    expect(notified, equals(3));
  });

  test('- finite() cancelation - using CancellableToken', () async {
    final pool = TestWorkerPool(ConcurrencySettings.oneIoThread);

    final digits = <int>[];
    int count = 0;

    final N = 20;

    final token = CancellationToken();
    Timer(TestService.delay * N, token.cancel);

    expect(token.cancelled, isFalse);

    try {
      await for (var n in pool.finite(50 * N, token)) {
        digits.add(n);
        count++;
      }
      // should never happen
      throw Exception('finite() completed successfully');
    } catch (e) {
      expect(e, isA<CancelledException>());
    }

    expect(token.cancelled, isTrue);
    expect(count, isPositive);
    expect(count, lessThanOrEqualTo(N));
    expect(digits, equals(Iterable.generate(count)));

    pool.stop();
  });

  test('- infinite() cancellation - using CancellableToken', () async {
    final pool = TestWorkerPool(ConcurrencySettings.oneIoThread);

    final digits = <int>[];
    int count = 0;

    final N = 20;

    var token = CancellationToken();
    Timer(TestService.delay * N, token.cancel);

    try {
      await for (var n in pool.infinite(token)) {
        digits.add(n);
        count++;
      }
      // should never happen
      throw Exception('infinite() completed sucessfully');
    } on CancelledException catch (ex) {
      expect(ex, isA<CancelledException>());
    }

    expect(token.cancelled, isTrue);
    expect(count, isPositive);
    expect(count, lessThanOrEqualTo(N));
    expect(digits, equals(Iterable.generate(count)));
  });

  test('- finite() cancellation - using TimeOutToken', () async {
    final pool = TestWorkerPool(ConcurrencySettings.oneIoThread);

    final digits = <int>[];
    int count = 0;

    final N = 10;

    final token = TimeOutToken(TestService.delay * N);

    try {
      await for (var n in pool.finite(50 * N, token)) {
        digits.add(n);
        count++;
      }
      // should never happen
      throw Exception('finite() completed successfully');
    } catch (ex) {
      expect(ex, isA<TaskTimeoutException>());
    }

    expect(pool.pendingWorkload, isZero);
    expect(token.cancelled, isTrue);
    expect(count, isPositive);
    expect(count, lessThanOrEqualTo(N));
    expect(digits, equals(Iterable.generate(count)));

    pool.stop();
  });

  test('- infinite() cancellation - using TimeOutToken', () async {
    final pool = TestWorkerPool(ConcurrencySettings.oneIoThread);

    final digits = <int>[];
    int count = 0;

    final N = 20;

    final token = TimeOutToken(TestService.delay * N);

    try {
      await for (var n in pool.infinite(token)) {
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

    pool.cancel();
    pool.stop();
  });

  test('- finite() cancellation - using CompositeToken', () async {
    final pool = TestWorkerPool(ConcurrencySettings.oneIoThread);

    final digits = <int>[];
    int count = 0;

    final N = 20;

    final timeout1 = TimeOutToken(TestService.delay * N);
    final token1 = CancellationToken();
    Timer(timeout1.duration * 0.5, token1.cancel);
    final composite1 = CompositeToken([timeout1, token1], CompositeMode.any);

    expect(timeout1.started, isFalse);

    try {
      await for (var n in pool.finite(50 * N, composite1)) {
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
    expect(token1.cancelled, isTrue);
    expect(count, isPositive);
    expect(count, lessThanOrEqualTo(N));
    expect(digits, equals(Iterable.generate(count)));

    digits.clear();
    count = 0;

    final timeout2 = TimeOutToken(TestService.delay * N);
    final token2 = CancellationToken();
    final composite2 = CompositeToken([timeout2, token2], CompositeMode.any);

    expect(timeout2.started, isFalse);

    try {
      await for (var n in pool.finite(50 * N, composite2)) {
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
    expect(token2.cancelled, isFalse);
    expect(count, isPositive);
    expect(count, lessThanOrEqualTo(N));
    expect(digits, equals(Iterable.generate(count)));

    pool.cancel();
    pool.stop();
  });

  test('- infinite() cancellation - using CompositeToken', () async {
    final pool = TestWorkerPool(ConcurrencySettings.oneIoThread);

    final digits = <int>[];
    int count = 0;

    final N = 20;

    final timeout1 = TimeOutToken(TestService.delay * N);
    final token1 = CancellationToken();
    Timer(timeout1.duration * 0.5, token1.cancel);
    final composite1 = CompositeToken([timeout1, token1], CompositeMode.any);

    expect(timeout1.started, isFalse);

    try {
      await for (var n in pool.infinite(composite1)) {
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
    expect(token1.cancelled, isTrue);
    expect(count, isPositive);
    expect(count, lessThanOrEqualTo(N));
    expect(digits, equals(Iterable.generate(count)));

    digits.clear();
    count = 0;

    final timeout2 = TimeOutToken(TestService.delay * N);
    final token2 = CancellationToken();
    final composite2 = CompositeToken([timeout2, token2], CompositeMode.any);

    try {
      await for (var n in pool.infinite(composite2)) {
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

    pool.cancel();
    pool.stop();
  });

  test('- finite() cancellation - using a shared CancellableToken', () async {
    final pool = TestWorkerPool(concurrencySettings_222);

    final L = 20;

    var token = CancellationToken();

    int success = 0;
    int errors = 0;

    final tasks = <Future>[];
    for (var i = 0; i < 2 * pool.maxConcurrency + 1; i++) {
      tasks.add(pool.finite(L, token).toList().then((list) {
        success++;
        return list;
      }).onError((ex, st) {
        errors++;
        return []; /* swallow errors */
      }));
    }

    expect(success, isZero);
    expect(errors, isZero);

    Future.delayed(TestService.delay * L * 1.75, token.cancel);

    await Future.wait(tasks);

    expect(token.cancelled, isTrue);
    expect(success, equals(pool.maxConcurrency));
    expect(success + errors, equals(tasks.length));

    pool.cancel();
    pool.stop();
  });

  test('- finite() cancellation - using a shared TimeOutToken', () async {
    final pool = TestWorkerPool(concurrencySettings_222);

    final L = 10;

    var timeout = TimeOutToken(TestService.delay * L * 1.5);

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

  test('- finite() cancellation - using a shared CompositeToken', () async {
    final pool = TestWorkerPool(concurrencySettings_222);

    final L = 50;

    final timeout1 = TimeOutToken(TestService.delay * L * 1.5);
    final token1 = CancellationToken();
    final composite1 = CompositeToken([timeout1, token1], CompositeMode.any);

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
    expect(token1.cancelled, isFalse);
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
}
