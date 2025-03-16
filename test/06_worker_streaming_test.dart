// ignore_for_file: file_names

import 'dart:async';

import 'package:squadron/squadron.dart';
import 'package:test/test.dart';
import 'package:using/using.dart';

import 'src/test_context.dart';
import 'src/utils.dart';
import 'test_constants.dart';
import 'test_exception.dart';
import 'worker_services/streaming_service_worker.dart';
import 'worker_services/test_service_worker.dart';

Future<void> main() => TestContext.run(execute);

const testScript = '06_worker_streaming_test.dart';

void execute(TestContext? tc) {
  if (tc == null) return;

  tc.launch(() {
    tc.group('- SQUADRON WORKER - STREAMING', () {
      tc.test('- With cancelOnError = false', () async {
        await TestWorker(tc).useAsync((w) async {
          final done = Completer();
          final numbers = <int>[];
          final errors = <SquadronException>[];
          final maxErrors = 3;

          var pending = await w.getPendingInfiniteWithErrors();
          expect(pending, isZero);

          late final StreamSubscription sub;
          sub = w.infiniteWithErrors().listen(
            numbers.add,
            onError: (ex) {
              errors.add(ex);
              if (errors.length >= maxErrors) {
                sub.cancel().then(done.complete);
              }
            },
            onDone: done.complete,
            cancelOnError: false,
          );

          pending = await w.getPendingInfiniteWithErrors();
          expect(pending, 1);

          await done.future;

          expect(errors, hasLength(maxErrors));
          expect(numbers, hasLength(greaterThan(maxErrors)));
          expect(errors, everyElement(reports('error #\\d+')));

          pending = await w.getPendingInfiniteWithErrors();
          expect(pending, isZero);
        });
      });

      tc.test('- With cancelOnError = true', () async {
        await TestWorker(tc).useAsync((w) async {
          final numbers = <int>[];

          var pending = await w.getPendingInfiniteWithErrors();
          expect(pending, isZero);

          try {
            final completer = Completer();
            w.infiniteWithErrors().listen(
                  numbers.add,
                  onError: completer.completeError,
                  onDone: completer.complete,
                  cancelOnError: true,
                );

            pending = await w.getPendingInfiniteWithErrors();
            expect(pending, 1);

            final res = await completer.future;
            throw unexpectedSuccess('infiniteWithErrors()', res);
          } on WorkerException catch (ex) {
            expect(ex, reports('error #\\d+'));
          }

          expect(numbers, [0, 1, 2]);

          pending = await w.getPendingInfiniteWithErrors();
          expect(pending, isZero);
        });
      });

      tc.test('- With "await for"', () async {
        await TestWorker(tc).useAsync((w) async {
          final numbers = <int>[];

          try {
            await for (var number in w.infiniteWithErrors()) {
              final pending = await w.getPendingInfiniteWithErrors();
              expect(pending, 1);
              numbers.add(number);
            }
            throw unexpectedSuccess('infiniteWithErrors()');
          } on WorkerException catch (ex) {
            expect(ex, reports('error #\\d+'));
          }

          expect(numbers, [0, 1, 2]);

          final pending = await w.getPendingInfiniteWithErrors();
          expect(pending, isZero);
        });
      });

      tc.test('- Throwing in "await for"', () async {
        await TestWorker(tc).useAsync((w) async {
          final numbers = <int>[];

          try {
            await for (var number in w.infiniteWithErrors()) {
              final pending = await w.getPendingInfiniteWithErrors();
              expect(pending, 1);
              if (numbers.isEmpty) {
                numbers.add(number);
              } else {
                throw TestException('client-side exception');
              }
            }
            throw unexpectedSuccess('infiniteWithErrors()');
          } on TestException catch (ex) {
            expect(ex, reports('client-side exception'));
          }

          expect(numbers, [0]);

          final pending = await w.getPendingInfiniteWithErrors();
          expect(pending, isZero);
        });
      });

      tc.test('- Pause & resume', () async {
        await TestWorker(tc).useAsync((w) async {
          var pending = await w.getPendingInfiniteWithErrors();
          expect(pending, isZero);

          final numbers = <int>[];
          final errors = <SquadronException>[];

          final sub = w
              .infiniteWithErrors()
              .listen(numbers.add, onError: errors.add, cancelOnError: false);

          int countNumbers = 0;
          int countErrors = 0;
          int paused = 0;

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
          await Future.delayed(delay_80ms);
          expect(numbers, isEmpty);
          expect(errors, isEmpty);
          // resume
          resume();

          await Future.delayed(delay_80ms);
          pause();
          pause();
          await Future.delayed(delay_80ms);
          resume();
          await Future.delayed(delay_80ms);
          resume();
          await Future.delayed(delay_80ms);

          await sub.cancel();

          expect(numbers, hasLength(greaterThan(countNumbers)));
          expect(errors, hasLength(greaterThan(countErrors)));
          expect(errors, everyElement(reports('error #\\d+')));

          await Future.delayed(delay_80ms);

          pending = await w.getPendingInfiniteWithErrors();
          expect(pending, isZero);
        });
      });

      tc.test('- Immediate cancelation', () async {
        await TestWorker(tc).useAsync((w) async {
          var pending = await w.getPendingInfiniteWithErrors();
          expect(pending, isZero);

          final numbers = <int>[];
          final errors = <SquadronException>[];

          final sub = w
              .infiniteWithErrors()
              .listen(numbers.add, onError: errors.add, cancelOnError: false);
          expect(numbers, isEmpty);
          expect(errors, isEmpty);

          await sub.cancel();
          expect(numbers, isEmpty);
          expect(errors, isEmpty);

          await Future.delayed(delay_80ms);
          expect(numbers, isEmpty);
          expect(errors, isEmpty);

          pending = await w.getPendingInfiniteWithErrors();
          expect(pending, isZero);
        });
      });

      tc.test('- Subscription cancelation', () async {
        StreamingServiceWorker(tc).useAsync((w) async {
          expect(await w.getMonitored(), 0);

          var nb1 = 0;
          final sub1 = w.monitoredStream().listen((_) => nb1++);

          await Future.delayed(delay_80ms);

          expect(await w.getMonitored(), 1);
          expect(nb1, isPositive);

          var nb2 = 0;
          final sub2 = w.monitoredStream().listen((_) => nb2++);

          await Future.delayed(delay_80ms);

          expect(await w.getMonitored(), 2);
          expect(nb2, isPositive);

          await sub1.cancel();

          final nb1_1 = nb1, nb2_1 = nb2;
          await Future.delayed(delay_80ms);

          expect(nb1, nb1_1);
          expect(nb2, greaterThan(nb2_1));

          expect(await w.getMonitored(), 1);

          final nb1_2 = nb1, nb2_2 = nb2;
          await Future.delayed(delay_80ms);

          expect(nb1, nb1_2);
          expect(nb2_2, greaterThan(nb2_1));
          expect(nb2, greaterThan(nb2_2));

          await sub2.cancel();

          final nb1_3 = nb1, nb2_3 = nb2;
          await Future.delayed(delay_80ms);

          expect(nb1, nb1_3);
          expect(nb2_3, greaterThan(nb2_2));
          expect(nb2, nb2_3);

          expect(await w.getMonitored(), 0);
        });
      });
    });
  });
}
