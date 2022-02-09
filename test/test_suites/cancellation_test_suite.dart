import 'dart:async';

import 'package:test/test.dart';

import 'package:squadron/squadron.dart';

import '../classes/worker_entry_points.dart';

import '../worker_services/sample_service.dart';
import '../worker_services/sample_service_worker.dart';

void cancellationTests() {
  test('value task cancellation', () async {
    final concurrencySettings =
        ConcurrencySettings(minWorkers: 2, maxWorkers: 2, maxParallel: 2);

    final pool = SampleWorkerPool(getEntryPoint('sample'), concurrencySettings);
    await pool.start();

    final N = 2 *
        concurrencySettings.maxWorkers *
        (concurrencySettings.maxParallel + 1);

    final digits = <int>[];
    var errors = 0;

    final tasks = <Future>[];
    for (var i = 0; i < N; i++) {
      tasks.add(pool.delayedIdentity(i).then((value) {
        digits.add(value);
      }).catchError((e) {
        errors += 1;
      }));
    }

    await Future.delayed(
        Duration(milliseconds: (SampleService.delay * 1.5).toInt()));
    pool.cancel();

    await Future.wait(tasks);

    expect(digits.length, isPositive);
    expect(errors, isPositive);
    expect(digits.length + errors, equals(N));

    pool.stop();
  });

  test('stream task cancellation', () async {
    final concurrencySettings =
        ConcurrencySettings(minWorkers: 2, maxWorkers: 2, maxParallel: 2);

    final pool = SampleWorkerPool(getEntryPoint('sample'), concurrencySettings);
    await pool.start();

    final N = 2 *
        concurrencySettings.maxWorkers *
        (concurrencySettings.maxParallel + 1);

    final results = <int, List<dynamic>?>{};

    final tasks = <Future>[];
    for (var i = 0; i < N; i++) {
      final completer = Completer();
      tasks.add(completer.future);
      pool.delayedSequence(i + 1).listen((value) {
        results[i] ??= <dynamic>[];
        results[i]!.add(value);
      }, onError: (error) {
        results[i] ??= <dynamic>[];
        results[i]!.add(error);
      }, onDone: () {
        completer.complete();
      });
    }
    await Future.delayed(
        Duration(milliseconds: (SampleService.delay * 2.5).toInt()));
    pool.cancel();

    await Future.wait(tasks);

    // all streams have been executed or cancelled
    expect(results.length, equals(N));

    final fullExecution =
        results.values.where((r) => r!.every((e) => e is int)).length;
    final partialExecution = results.values
        .where((r) =>
            r!.any((e) => e is int) && r.any((e) => e is CancelledException))
        .length;
    final fullCancellation = results.values
        .where((r) => r!.every((e) => e is CancelledException))
        .length;
    final severalErrors = results.values
        .where((r) => r!.whereType<CancelledException>().length > 1)
        .length;

    expect(fullExecution, isPositive);
    expect(partialExecution, isPositive);
    expect(fullCancellation, isPositive);
    expect(severalErrors, isZero);
    expect(fullExecution + partialExecution + fullCancellation, equals(N));

    pool.stop();
  });

  test('specific value task cancellation (WorkerPool.cancel)', () async {
    final concurrencySettings =
        ConcurrencySettings(minWorkers: 2, maxWorkers: 2, maxParallel: 3);

    final pool = SampleWorkerPool(getEntryPoint('sample'), concurrencySettings);
    await pool.start();

    final maxRunning =
        concurrencySettings.maxWorkers * concurrencySettings.maxParallel;

    final N = 2 * (maxRunning + concurrencySettings.maxWorkers);

    final digits = <int>[];
    var errors = 0;

    final tasks = <ValueTask>[];
    final futures = <Future>[];
    for (var i = 0; i < N; i++) {
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

    await Future.delayed(
        Duration(milliseconds: (SampleService.delay * 1.5).toInt()));
    pool.cancel(tasks[N - 1]);
    expect(tasks[N - 1].isCancelled, isTrue);
    expect(tasks.where((t) => t.isRunning).length, equals(maxRunning));

    await Future.wait(futures);

    expect(tasks.where((t) => t.isCancelled).length, equals(2));
    expect(tasks.where((t) => t.isRunning).length, isZero);
    expect(tasks.where((t) => t.isFinished).length, equals(N - 2));

    expect(errors, equals(2));
    expect(digits.length, isPositive);
    expect(digits.length + errors, equals(N));

    pool.stop();
  });

  test('specific value task cancellation (ValueTask.cancel)', () async {
    final concurrencySettings =
        ConcurrencySettings(minWorkers: 2, maxWorkers: 2, maxParallel: 3);

    final pool = SampleWorkerPool(getEntryPoint('sample'), concurrencySettings);
    await pool.start();

    final maxRunning =
        concurrencySettings.maxWorkers * concurrencySettings.maxParallel;

    final N = 2 * (maxRunning + concurrencySettings.maxWorkers);

    final digits = <int>[];
    var errors = 0;

    final tasks = <ValueTask>[];
    final futures = <Future>[];
    for (var i = 0; i < N; i++) {
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

    await Future.delayed(
        Duration(milliseconds: (SampleService.delay * 1.5).toInt()));
    tasks[N - 1].cancel();
    expect(tasks[N - 1].isCancelled, isTrue);
    expect(tasks.where((t) => t.isRunning).length, equals(maxRunning));

    await Future.wait(futures);

    expect(tasks.where((t) => t.isCancelled).length, equals(2));
    expect(tasks.where((t) => t.isRunning).length, isZero);
    expect(tasks.where((t) => t.isFinished).length, equals(N - 2));

    expect(errors, equals(2));
    expect(digits.length, isPositive);
    expect(digits.length + errors, equals(N));

    pool.stop();
  });

  test('specific stream task cancellation (WorkerPool.cancel)', () async {
    final concurrencySettings =
        ConcurrencySettings(minWorkers: 2, maxWorkers: 2, maxParallel: 3);

    final pool = SampleWorkerPool(getEntryPoint('sample'), concurrencySettings);
    await pool.start();

    final maxRunning =
        concurrencySettings.maxWorkers * concurrencySettings.maxParallel;

    final N = 2 * (maxRunning + concurrencySettings.maxWorkers);

    final status = <int, String>{};
    var errors = 0;

    final tasks = <StreamTask>[];
    final futures = <Future>[];
    for (var i = 0; i < N; i++) {
      final task = pool.delayedSequenceTask(i + 2);
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

    await Future.delayed(
        Duration(milliseconds: (SampleService.delay * 1.5).toInt()));
    pool.cancel(tasks[0]);
    expect(tasks[0].isCancelled, isTrue);

    await Future.delayed(
        Duration(milliseconds: (SampleService.delay * 2.5).toInt()));
    pool.cancel(tasks[N - 1]);
    expect(tasks[N - 1].isCancelled, isTrue);
    expect(tasks.where((t) => t.isRunning).length, equals(maxRunning));

    await Future.wait(futures);

    expect(tasks.where((t) => t.isCancelled).length, equals(2));
    expect(tasks.where((t) => t.isRunning).length, isZero);
    expect(tasks.where((t) => t.isFinished).length, equals(N - 2));

    expect(errors, equals(2));
    expect(status.values.where((s) => s == 'started').length, isZero);
    expect(status.values.where((s) => s == 'interrupted').length, equals(1));
    expect(status.values.where((s) => s == 'cancelled').length, equals(1));
    expect(status.values.where((s) => s == 'completed').length,
        equals(N - errors));

    pool.stop();
  });

  test('specific stream task cancellation (StreamTask.cancel)', () async {
    final concurrencySettings =
        ConcurrencySettings(minWorkers: 2, maxWorkers: 2, maxParallel: 3);

    final pool = SampleWorkerPool(getEntryPoint('sample'), concurrencySettings);
    await pool.start();

    final maxRunning =
        concurrencySettings.maxWorkers * concurrencySettings.maxParallel;

    final N = 2 * (maxRunning + concurrencySettings.maxWorkers);

    final status = <int, String>{};
    var errors = 0;

    final tasks = <StreamTask>[];
    final futures = <Future>[];
    for (var i = 0; i < N; i++) {
      final task = pool.delayedSequenceTask(i + 2);
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

    await Future.delayed(
        Duration(milliseconds: (SampleService.delay * 1.5).toInt()));
    tasks[0].cancel();
    expect(tasks[0].isCancelled, isTrue);

    await Future.delayed(
        Duration(milliseconds: (SampleService.delay * 2.5).toInt()));
    tasks[N - 1].cancel();
    expect(tasks[N - 1].isCancelled, isTrue);
    expect(tasks.where((t) => t.isRunning).length, equals(maxRunning));

    await Future.wait(futures);

    expect(tasks.where((t) => t.isCancelled).length, equals(2));
    expect(tasks.where((t) => t.isRunning).length, isZero);
    expect(tasks.where((t) => t.isFinished).length, equals(N - 2));

    expect(errors, equals(2));
    expect(status.values.where((s) => s == 'started').length, isZero);
    expect(status.values.where((s) => s == 'interrupted').length, equals(1));
    expect(status.values.where((s) => s == 'cancelled').length, equals(1));
    expect(status.values.where((s) => s == 'completed').length,
        equals(N - errors));

    pool.stop();
  });

  test('cancellable token - worker without token', () async {
    final concurrencySettings =
        ConcurrencySettings(minWorkers: 1, maxWorkers: 1, maxParallel: 1);

    final pool = SampleWorkerPool(getEntryPoint('sample'), concurrencySettings);
    await pool.start();

    final digits = <int>[];
    int count = 0;

    final N = 15;

    final token = CancellableToken();
    Timer(Duration(milliseconds: N * SampleService.delay), () {
      token.cancel();
    });

    try {
      await for (var n in pool.delayedSequence(10 * N, token)) {
        digits.add(n - 1);
        count++;
      }
      expect(true, isFalse);
    } catch (e) {
      expect(e, isA<CancelledException>());
    }

    expect(count, isPositive);
    expect(count, lessThanOrEqualTo(N));
    expect(digits, equals(Iterable.generate(count)));

    pool.stop();
  });

  test('cancellable token - worker with token', () async {
    final concurrencySettings =
        ConcurrencySettings(minWorkers: 1, maxWorkers: 1, maxParallel: 1);

    final pool = SampleWorkerPool(getEntryPoint('sample'), concurrencySettings);
    await pool.start();

    final digits = <int>[];
    int count = 0;

    final N = 15;

    var token = CancellableToken();
    Timer(Duration(milliseconds: N * SampleService.delay), () {
      token.cancel();
    });

    try {
      await for (var n in pool.cancellableSequence(token)) {
        digits.add(n);
        count++;
      }
      expect(true, isFalse);
    } on CancelledException catch (ex) {
      expect(ex, isA<CancelledException>());
    }

    expect(count, isPositive);
    expect(count, lessThanOrEqualTo(N));
    expect(digits, equals(Iterable.generate(count)));
  });

  test('timeout token - worker without token', () async {
    final concurrencySettings =
        ConcurrencySettings(minWorkers: 1, maxWorkers: 1, maxParallel: 1);

    final pool = SampleWorkerPool(getEntryPoint('sample'), concurrencySettings);
    await pool.start();

    final digits = <int>[];
    int count = 0;

    final N = 15;

    final token = TimeOutToken(Duration(milliseconds: N * SampleService.delay));

    try {
      await for (var n in pool.delayedSequence(10 * N, token)) {
        digits.add(n - 1);
        count++;
      }
      expect(true, isFalse);
    } on WorkerException catch (ex) {
      expect(ex, isA<TaskTimeoutException>());
    }

    expect(count, isPositive);
    expect(count, lessThanOrEqualTo(N));
    expect(digits, equals(Iterable.generate(count)));

    pool.cancel();
    pool.stop();
  });

  test('timeout token - worker with token', () async {
    final concurrencySettings =
        ConcurrencySettings(minWorkers: 1, maxWorkers: 1, maxParallel: 1);

    final pool = SampleWorkerPool(getEntryPoint('sample'), concurrencySettings);
    await pool.start();

    final digits = <int>[];
    int count = 0;

    final N = 15;

    final token = TimeOutToken(Duration(milliseconds: N * SampleService.delay));

    try {
      await for (var n in pool.cancellableSequence(token)) {
        digits.add(n);
        count++;
      }
      expect(true, isFalse);
    } on WorkerException catch (ex) {
      expect(ex, isA<TaskTimeoutException>());
    }

    expect(count, isPositive);
    expect(count, lessThanOrEqualTo(N));
    expect(digits, equals(Iterable.generate(count)));

    pool.cancel();
    pool.stop();
  });

  test('composite cancellation token - worker without token', () async {
    final concurrencySettings =
        ConcurrencySettings(minWorkers: 1, maxWorkers: 1, maxParallel: 1);

    final pool = SampleWorkerPool(getEntryPoint('sample'), concurrencySettings);
    await pool.start();

    final digits = <int>[];
    int count = 0;

    final N = 15;

    final timeout1 =
        TimeOutToken(Duration(milliseconds: N * SampleService.delay));
    final token1 = CancellableToken();
    Timer(timeout1.duration * 0.5, token1.cancel);
    final composite1 = CompositeToken([timeout1, token1], CompositeMode.any);

    try {
      await for (var n in pool.delayedSequence(10 * N, composite1)) {
        digits.add(n - 1);
        count++;
      }
      expect(true, isFalse);
    } on WorkerException catch (ex) {
      expect(ex, isA<CancelledException>());
    }

    expect(count, isPositive);
    expect(count, lessThanOrEqualTo(N));
    expect(digits, equals(Iterable.generate(count)));

    digits.clear();
    count = 0;

    final timeout2 =
        TimeOutToken(Duration(milliseconds: N * SampleService.delay));
    final token2 = CancellableToken();
    final composite2 = CompositeToken([timeout2, token2], CompositeMode.any);

    try {
      await for (var n in pool.delayedSequence(10 * N, composite2)) {
        digits.add(n - 1);
        count++;
      }
      expect(true, isFalse);
    } on WorkerException catch (ex) {
      expect(ex, isA<TaskTimeoutException>());
    }

    expect(count, isPositive);
    expect(count, lessThanOrEqualTo(N));
    expect(digits, equals(Iterable.generate(count)));

    pool.cancel();
    pool.stop();
  });

  test('composite cancellation token - worker with token', () async {
    final concurrencySettings =
        ConcurrencySettings(minWorkers: 1, maxWorkers: 1, maxParallel: 1);

    final pool = SampleWorkerPool(getEntryPoint('sample'), concurrencySettings);
    await pool.start();

    final digits = <int>[];
    int count = 0;

    final N = 15;

    final timeout1 =
        TimeOutToken(Duration(milliseconds: N * SampleService.delay));
    final token1 = CancellableToken();
    Timer(timeout1.duration * 0.5, token1.cancel);
    final composite1 = CompositeToken([timeout1, token1], CompositeMode.any);

    try {
      await for (var n in pool.cancellableSequence(composite1)) {
        digits.add(n);
        count++;
      }
      expect(true, isFalse);
    } on WorkerException catch (ex) {
      expect(ex, isA<CancelledException>());
    }

    expect(count, isPositive);
    expect(count, lessThanOrEqualTo(N));
    expect(digits, equals(Iterable.generate(count)));

    digits.clear();
    count = 0;

    final timeout2 =
        TimeOutToken(Duration(milliseconds: N * SampleService.delay));
    final token2 = CancellableToken();
    final composite2 = CompositeToken([timeout2, token2], CompositeMode.any);

    try {
      await for (var n in pool.cancellableSequence(composite2)) {
        digits.add(n);
        count++;
      }
      expect(true, isFalse);
    } on WorkerException catch (ex) {
      expect(ex, isA<TaskTimeoutException>());
    }

    expect(count, isPositive);
    expect(count, lessThanOrEqualTo(N));
    expect(digits, equals(Iterable.generate(count)));

    pool.cancel();
    pool.stop();
  });

  test('cancellable token - sharing across tasks', () async {
    final concurrencySettings =
        ConcurrencySettings(minWorkers: 2, maxWorkers: 2, maxParallel: 2);

    final pool = SampleWorkerPool(getEntryPoint('sample'), concurrencySettings);
    await pool.start();

    final N = concurrencySettings.maxWorkers * concurrencySettings.maxParallel;

    var token = CancellableToken();

    int success = 0;
    int errors = 0;

    final tasks = <Future>[];
    for (var i = 0; i < 2 * N + 1; i++) {
      tasks.add(pool.delayedSequence(4, token).toList().then((list) {
        success++;
        return list;
      }).onError((error, stackTrace) {
        errors++;
        return []; /* swallow errors */
      }));
    }

    expect(success, isZero);
    expect(errors, isZero);

    Future.delayed(
        Duration(milliseconds: 5 * SampleService.delay), token.cancel);

    await Future.wait(tasks);

    expect(success, equals(N));
    expect(success + errors, equals(tasks.length));

    pool.cancel();
    pool.stop();
  });

  test('timeout token - sharing across tasks', () async {
    final concurrencySettings =
        ConcurrencySettings(minWorkers: 2, maxWorkers: 2, maxParallel: 2);

    final pool = SampleWorkerPool(getEntryPoint('sample'), concurrencySettings);
    await pool.start();

    final N = concurrencySettings.maxWorkers * concurrencySettings.maxParallel;

    var token = TimeOutToken(Duration(milliseconds: 5 * SampleService.delay));

    int success = 0;
    int errors = 0;

    final tasks = <Future>[];
    for (var i = 0; i < 2 * N + 1; i++) {
      tasks.add(pool.delayedSequence(4, token).toList().then((list) {
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

    expect(success, equals(N));
    expect(success + errors, equals(tasks.length));

    pool.cancel();
    pool.stop();
  });

  test('composite token - sharing across tasks', () async {
    final concurrencySettings =
        ConcurrencySettings(minWorkers: 2, maxWorkers: 2, maxParallel: 2);

    final pool = SampleWorkerPool(getEntryPoint('sample'), concurrencySettings);
    await pool.start();

    final N = concurrencySettings.maxWorkers * concurrencySettings.maxParallel;

    final timeout1 =
        TimeOutToken(Duration(milliseconds: 5 * SampleService.delay));
    final token1 = CancellableToken();
    final composite1 = CompositeToken([timeout1, token1], CompositeMode.any);

    int success = 0;
    int errors = 0;

    final tasks = <Future>[];
    for (var i = 0; i < 2 * N + 1; i++) {
      tasks.add(pool.delayedSequence(4, composite1).toList().then((list) {
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

    expect(success, equals(N));
    expect(success + errors, equals(tasks.length));

    final timeout2 =
        TimeOutToken(Duration(milliseconds: 10 * SampleService.delay));
    final token2 = CancellableToken();
    final composite2 = CompositeToken([timeout2, token2], CompositeMode.any);

    success = 0;
    errors = 0;

    tasks.clear();
    for (var i = 0; i < 2 * N + 1; i++) {
      tasks.add(pool.delayedSequence(4, composite2).toList().then((list) {
        success++;
        return list;
      }).onError((error, stackTrace) {
        errors++;
        return []; /* swallow errors */
      }));
    }

    expect(success, isZero);
    expect(errors, isZero);

    Timer(Duration(milliseconds: 6 * SampleService.delay), token2.cancel);

    await Future.wait(tasks);

    expect(success, equals(N));
    expect(success + errors, equals(tasks.length));

    pool.cancel();
    pool.stop();
  });
}
