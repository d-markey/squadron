import 'dart:async';

import 'package:test/test.dart';

import 'package:squadron/squadron.dart';

import '../worker_services/test_service.dart';
import '../worker_services/test_service_worker.dart';

const concurrencySettings_222 =
    ConcurrencySettings(minWorkers: 2, maxWorkers: 2, maxParallel: 2);

void cancellationTests() {
  test('CancellationToken cannot be listened to - Worker', () async {
    final worker = TestWorker();

    final token = CancellableToken();
    var result = await worker.cannotListen(token);
    expect(result, isTrue);

    final timeout = TimeOutToken(Duration(seconds: 1));
    result = await worker.cannotListen(timeout);
    expect(result, isTrue);
  });

  test('value task cancellation - using pool.cancel()', () async {
    final pool = TestWorkerPool(concurrencySettings_222);
    await pool.start();

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

    await Future.delayed(TestService.delay * 1.5);
    pool.cancel();

    await Future.wait(tasks);

    expect(digits.length, isPositive);
    expect(errors, isPositive);
    expect(digits.length + errors, equals(2 * pool.maxConcurrency + 1));

    pool.stop();
  });

  test('stream task cancellation - using pool.cancel()', () async {
    final pool = TestWorkerPool(concurrencySettings_222);
    await pool.start();

    final results = <int, List<dynamic>>{};

    final tasks = <Future>[];
    for (var i = 0; i < 2 * pool.maxConcurrency + 1; i++) {
      final completer = Completer();
      results[i] = [];
      tasks.add(completer.future);
      pool.finite(i + 1).listen((value) {
        results[i]!.add(value);
      }, onError: (error) {
        results[i]!.add(error);
      }, onDone: () {
        completer.complete();
      });
    }
    await Future.delayed(TestService.delay * 2.5);
    pool.cancel();

    await Future.wait(tasks);

    // all streams have been executed or cancelled
    expect(results.length, equals(2 * pool.maxConcurrency + 1));

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
        equals(2 * pool.maxConcurrency + 1));

    pool.stop();
  });

  test('specific value task cancellation - using pool.cancel(task)', () async {
    final pool = TestWorkerPool(concurrencySettings_222);
    await pool.start();

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
        errors += 1;
        // swallow error
        return null;
      }));
    }

    pool.cancel(tasks[0]);
    expect(tasks[0].isCancelled, isTrue);

    await Future.delayed(TestService.delay * 1.5);
    pool.cancel(tasks[3 * pool.maxConcurrency]);
    expect(tasks[3 * pool.maxConcurrency].isCancelled, isTrue);

    await Future.wait(futures);

    expect(tasks.where((t) => t.isCancelled).length, equals(2));
    expect(tasks.where((t) => t.isRunning).length, isZero);
    expect(tasks.where((t) => t.isFinished).length,
        equals(3 * pool.maxConcurrency - 1));

    expect(errors, equals(2));
    expect(digits.length, isPositive);
    expect(digits.length + errors, equals(3 * pool.maxConcurrency + 1));

    pool.stop();
  });

  test('specific value task cancellation - using task.cancel()', () async {
    final pool = TestWorkerPool(concurrencySettings_222);
    await pool.start();

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
        errors += 1;
        // swallow error
        return null;
      }));
    }

    tasks[0].cancel();
    expect(tasks[0].isCancelled, isTrue);

    await Future.delayed(TestService.delay * 1.5);
    tasks[3 * pool.maxConcurrency].cancel();
    expect(tasks[3 * pool.maxConcurrency].isCancelled, isTrue);

    await Future.wait(futures);

    expect(tasks.where((t) => t.isCancelled).length, equals(2));
    expect(tasks.where((t) => t.isRunning).length, isZero);
    expect(tasks.where((t) => t.isFinished).length,
        equals(3 * pool.maxConcurrency - 1));

    expect(errors, equals(2));
    expect(digits.length, isPositive);
    expect(digits.length + errors, equals(3 * pool.maxConcurrency + 1));

    pool.stop();
  });

  test('specific stream task cancellation - using pool.cancel(task)', () async {
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
    expect(tasks.where((t) => t.isRunning).length, isZero);
    expect(tasks.where((t) => t.isFinished).length,
        equals(2 * pool.maxConcurrency - 1));

    expect(errors, equals(2));
    expect(status.values.where((s) => s == 'started').length, isZero);
    expect(status.values.where((s) => s == 'interrupted').length, equals(1));
    expect(status.values.where((s) => s == 'cancelled').length, equals(1));
    expect(status.values.where((s) => s == 'completed').length,
        equals(2 * pool.maxConcurrency + 1 - errors));

    pool.stop();
  });

  test('specific stream task cancellation - using task.cancel()', () async {
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
    expect(tasks.where((t) => t.isRunning).length, isZero);
    expect(tasks.where((t) => t.isFinished).length,
        equals(2 * pool.maxConcurrency - 1));

    expect(errors, equals(2));
    expect(status.values.where((s) => s == 'started').length, isZero);
    expect(status.values.where((s) => s == 'interrupted').length, equals(1));
    expect(status.values.where((s) => s == 'cancelled').length, equals(1));
    expect(status.values.where((s) => s == 'completed').length,
        equals(2 * pool.maxConcurrency + 1 - errors));

    pool.stop();
  });

  test('cancellable token - gets cancelled', () async {
    final token = CancellableToken();

    await Future.delayed(Duration(milliseconds: 10));
    expect(token.cancelled, isFalse);

    token.cancel();

    expect(token.cancelled, isTrue);
  });

  test('cancellable token - notifies listeners', () async {
    final token = CancellableToken();

    var notified = false;
    token.addListener(() => notified = true);

    token.cancel();

    expect(token.cancelled, isTrue);
    expect(notified, isTrue);
  });

  test('timeout token - is not programmatically cancellable', () async {
    final token = TimeOutToken(TestService.delay * 2);
    expect(() => token.cancel(), throwsA(isA<SquadronError>()));
  });

  test('timeout token - gets cancelled after specified duration', () async {
    final timeoutToken = TimeOutToken(TestService.delay * 2);
    timeoutToken.start();

    await Future.delayed(timeoutToken.duration * 0.5);
    expect(timeoutToken.cancelled, isFalse);

    await Future.delayed(timeoutToken.duration);
    expect(timeoutToken.cancelled, isTrue);
  });

  test('timeout token - notifies listeners', () async {
    final timeoutToken = TimeOutToken(TestService.delay * 2);
    timeoutToken.start();

    var notified = false;
    timeoutToken.addListener(() => notified = true);

    await Future.delayed(timeoutToken.duration);
    expect(timeoutToken.cancelled, isTrue);
    expect(notified, isTrue);
  });

  test('composite token - is not programmatically cancellable', () async {
    final cancellable = CancellableToken();
    final token = CompositeToken([cancellable], CompositeMode.any);
    expect(() => token.cancel(), throwsA(isA<SquadronError>()));
  });

  test('composite token - gets cancelled in CompositeMode.any', () async {
    final cancellable1 = CancellableToken();
    final cancellable2 = CancellableToken();
    final token =
        CompositeToken([cancellable1, cancellable2], CompositeMode.any);

    expect(token.cancelled, isFalse);
    cancellable1.cancel();
    expect(token.cancelled, isTrue);
  });

  test('composite token - gets cancelled in CompositeMode.all', () async {
    final cancellable1 = CancellableToken();
    final cancellable2 = CancellableToken();
    final token =
        CompositeToken([cancellable1, cancellable2], CompositeMode.all);

    expect(token.cancelled, isFalse);
    cancellable1.cancel();
    expect(token.cancelled, isFalse);
    cancellable2.cancel();
    expect(token.cancelled, isTrue);
  });

  test('composite token - gets cancelled by timeout token', () async {
    final timeoutToken = TimeOutToken(Duration(milliseconds: 30));
    final cancellableToken = CancellableToken();
    final token =
        CompositeToken([cancellableToken, timeoutToken], CompositeMode.any);
    timeoutToken.start();

    expect(timeoutToken.cancelled, isFalse);
    expect(cancellableToken.cancelled, isFalse);
    expect(token.cancelled, isFalse);

    await Future.delayed(timeoutToken.duration * 0.5);

    expect(timeoutToken.cancelled, isFalse);
    expect(cancellableToken.cancelled, isFalse);
    expect(token.cancelled, isFalse);

    await Future.delayed(timeoutToken.duration);

    expect(timeoutToken.cancelled, isTrue);
    expect(cancellableToken.cancelled, isFalse);
    expect(token.cancelled, isTrue);
  });

  test('composite token - notifies listeners', () async {
    final cancellable1 = CancellableToken();
    final cancellable2 = CancellableToken();
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

  test('finite() cancelation - using CancellableToken', () async {
    final pool = TestWorkerPool(ConcurrencySettings.oneIoThread);
    await pool.start();

    final digits = <int>[];
    int count = 0;

    final N = 20;

    final token = CancellableToken();
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

  test('infinite() cancellation - using CancellableToken', () async {
    final pool = TestWorkerPool(ConcurrencySettings.oneIoThread);
    await pool.start();

    final digits = <int>[];
    int count = 0;

    final N = 20;

    var token = CancellableToken();
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

  test('finite() cancellation - using TimeOutToken', () async {
    final pool = TestWorkerPool(ConcurrencySettings.oneIoThread);
    await pool.start();

    final digits = <int>[];
    int count = 0;

    final N = 20;

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

  test('infinite() cancellation - using TimeOutToken', () async {
    final pool = TestWorkerPool(ConcurrencySettings.oneIoThread);
    await pool.start();

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

  test('finite() cancellation - using CompositeToken', () async {
    final pool = TestWorkerPool(ConcurrencySettings.oneIoThread);
    await pool.start();

    final digits = <int>[];
    int count = 0;

    final N = 20;

    final timeout1 = TimeOutToken(TestService.delay * N);
    final token1 = CancellableToken();
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
    final token2 = CancellableToken();
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

  test('infinite() cancellation - using CompositeToken', () async {
    final pool = TestWorkerPool(ConcurrencySettings.oneIoThread);
    await pool.start();

    final digits = <int>[];
    int count = 0;

    final N = 20;

    final timeout1 = TimeOutToken(TestService.delay * N);
    final token1 = CancellableToken();
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
    final token2 = CancellableToken();
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

  test('finite() cancellation - using a shared CancellableToken', () async {
    final pool = TestWorkerPool(concurrencySettings_222);
    await pool.start();

    final L = 4;

    var token = CancellableToken();

    int success = 0;
    int errors = 0;

    final tasks = <Future>[];
    for (var i = 0; i < 2 * pool.maxConcurrency + 1; i++) {
      tasks.add(pool.finite(L, token).toList().then((list) {
        success++;
        return list;
      }).onError((error, stackTrace) {
        errors++;
        return []; /* swallow errors */
      }));
    }

    expect(success, isZero);
    expect(errors, isZero);

    Future.delayed(TestService.delay * L * 1.5, token.cancel);

    await Future.wait(tasks);

    expect(token.cancelled, isTrue);
    expect(success, equals(pool.maxConcurrency));
    expect(success + errors, equals(tasks.length));

    pool.cancel();
    pool.stop();
  });

  test('finite() cancellation - using a shared TimeOutToken', () async {
    final pool = TestWorkerPool(concurrencySettings_222);
    await pool.start();

    final L = 4;

    var timeout = TimeOutToken(TestService.delay * L * 1.5);

    int success = 0;
    int errors = 0;

    final tasks = <Future>[];
    for (var i = 0; i < 2 * pool.maxConcurrency + 1; i++) {
      tasks.add(pool.finite(L, timeout).toList().then((list) {
        success++;
        return list;
      }).onError((error, stackTrace) {
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

  test('finite() cancellation - using a shared CompositeToken', () async {
    final pool = TestWorkerPool(concurrencySettings_222);
    await pool.start();

    final L = 4;

    final timeout1 = TimeOutToken(TestService.delay * L * 1.5);
    final token1 = CancellableToken();
    final composite1 = CompositeToken([timeout1, token1], CompositeMode.any);

    int success = 0;
    int errors = 0;

    // launch 2 * pool.maxConcurrency + 1 tasks of length L ==> one task executes in ~ L * delay
    final tasks = <Future>[];
    for (var i = 0; i < 2 * pool.maxConcurrency + 1; i++) {
      tasks.add(pool.finite(L, composite1).toList().then((list) {
        success++;
        return list;
      }).onError((error, stackTrace) {
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
    final token2 = CancellableToken();
    final composite2 = CompositeToken([timeout2, token2], CompositeMode.any);

    success = 0;
    errors = 0;

    // launch 2 * pool.maxConcurrency + 1 tasks of length L ==> one task executes in ~ L * delay
    tasks.clear();
    for (var i = 0; i < 2 * pool.maxConcurrency + 1; i++) {
      tasks.add(pool.finite(L, composite2).toList().then((list) {
        success++;
        return list;
      }).onError((error, stackTrace) {
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
