// ignore_for_file: file_names

@TestOn('vm || browser')
library;

import 'dart:async';

import 'package:squadron/squadron.dart';
import 'package:test/test.dart';

import 'classes/custom_exception.dart';
import 'classes/test_context.dart';
import 'classes/utils.dart';
import 'worker_services/delays.dart';
import 'worker_services/test_service_worker.dart';

void main() async {
  final testContext = await TestContext.init('');
  execute(testContext);
}

String testScript = '04_worker_streaming_test.dart';

void execute(TestContext tc) {
  tc.run(() {
    tc.group("- Squadron Worker", () {
      tc.group('- streaming', () {
        late TestWorker worker;

        setUpAll(() {
          worker = TestWorker(tc);
          return worker.start();
        });

        tearDownAll(() {
          worker.stop();
        });

        tc.test('- cancelOnError: false', () async {
          final done = Completer();
          final numbers = <int>[];
          final errors = <SquadronException>[];
          final maxErrors = 3;

          var pending = await worker.getPendingInfiniteWithErrors();
          expect(pending, isZero);

          late final StreamSubscription sub;
          sub = worker.infiniteWithErrors().listen(
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

          pending = await worker.getPendingInfiniteWithErrors();
          expect(pending, 1);

          await done.future;

          expect(errors.length, maxErrors);
          expect(numbers.length, greaterThan(errors.length));
          expect(errors, everyElement(reports('error #\\d+')));

          pending = await worker.getPendingInfiniteWithErrors();
          expect(pending, isZero);
        });

        tc.test('- cancelOnError: true', () async {
          final numbers = <int>[];

          var pending = await worker.getPendingInfiniteWithErrors();
          expect(pending, isZero);

          try {
            final completer = Completer();
            worker.infiniteWithErrors().listen(
                  numbers.add,
                  onError: completer.completeError,
                  onDone: completer.complete,
                  cancelOnError: true,
                );

            pending = await worker.getPendingInfiniteWithErrors();
            expect(pending, 1);

            final res = await completer.future;
            throw unexpectedSuccess('infiniteWithErrors()', res);
          } on WorkerException catch (ex) {
            expect(ex, reports('error #\\d+'));
          }

          expect(numbers, [0, 1, 2]);

          pending = await worker.getPendingInfiniteWithErrors();
          expect(pending, isZero);
        });

        tc.test('- await for', () async {
          final numbers = <int>[];

          try {
            await for (var number in worker.infiniteWithErrors()) {
              final pending = await worker.getPendingInfiniteWithErrors();
              expect(pending, 1);
              numbers.add(number);
            }
            throw unexpectedSuccess('infiniteWithErrors()');
          } on WorkerException catch (ex) {
            expect(ex, reports('error #\\d+'));
          }

          expect(numbers, [0, 1, 2]);

          await pumpEventQueue();
          final pending = await worker.getPendingInfiniteWithErrors();
          expect(pending, isZero);
        });

        tc.test('- throwing in await for', () async {
          final numbers = <int>[];

          try {
            await for (var number in worker.infiniteWithErrors()) {
              final pending = await worker.getPendingInfiniteWithErrors();
              expect(pending, 1);
              if (numbers.isEmpty) {
                numbers.add(number);
              } else {
                throw CustomException('client-side exception');
              }
            }
            throw unexpectedSuccess('infiniteWithErrors()');
          } on CustomException catch (ex) {
            expect(ex, reports('client-side exception'));
          }

          expect(numbers, [0]);

          await pumpEventQueue();
          final pending = await worker.getPendingInfiniteWithErrors();
          expect(pending, isZero);
        });

        tc.test('- pause/resume', () async {
          var pending = await worker.getPendingInfiniteWithErrors();
          expect(pending, isZero);

          final numbers = <int>[];
          final errors = <SquadronException>[];

          final sub = worker
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
          await Future.delayed(TestDelays.delay);
          expect(numbers, isEmpty);
          expect(errors, isEmpty);
          // resume
          resume();

          await Future.delayed(TestDelays.delay);
          pause();
          pause();
          await Future.delayed(TestDelays.delay);
          resume();
          await Future.delayed(TestDelays.delay);
          resume();
          await Future.delayed(TestDelays.delay);

          await sub.cancel();

          expect(numbers, hasLength(greaterThan(countNumbers)));
          expect(errors, hasLength(greaterThan(countErrors)));
          expect(errors, everyElement(reports('error #\\d+')));

          await Future.delayed(TestDelays.delay);

          pending = await worker.getPendingInfiniteWithErrors();
          expect(pending, isZero);
        });

        tc.test('- immediate cancelation', () async {
          var pending = await worker.getPendingInfiniteWithErrors();
          expect(pending, isZero);

          final numbers = <int>[];
          final errors = <SquadronException>[];

          final sub = worker
              .infiniteWithErrors()
              .listen(numbers.add, onError: errors.add, cancelOnError: false);
          expect(numbers, isEmpty);
          expect(errors, isEmpty);

          await sub.cancel();
          expect(numbers, isEmpty);
          expect(errors, isEmpty);

          await Future.delayed(TestDelays.delay);
          expect(numbers, isEmpty);
          expect(errors, isEmpty);

          pending = await worker.getPendingInfiniteWithErrors();
          expect(pending, isZero);
        });

        tc.test('- subscription cancelation', () async {
          var counter = 0;
          final clock = worker.clock(frequency: 100);
          final sub = clock.listen((_) => counter++);
          await Future.delayed(Duration(milliseconds: 100));
          expect(counter, isPositive);
          await sub.cancel();
        });
      });
    });
  });
}
