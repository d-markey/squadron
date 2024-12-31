// ignore_for_file: file_names

@TestOn('vm || browser')
library;

import 'dart:async';

import 'package:logger/web.dart';
import 'package:squadron/squadron.dart';
import 'package:test/test.dart';
import 'package:using/using.dart';

import 'classes/custom_exception.dart';
import 'classes/memory_logger.dart';
import 'classes/test_context.dart';
import 'classes/utils.dart';
import 'worker_services/delays.dart';
import 'worker_services/installable_service_worker.dart';
import 'worker_services/test_service_worker.dart';

Future<void> main() => TestContext.run(execute);

const testScript = '04_worker_test.dart';

void execute(TestContext? tc) {
  if (tc == null) return;

  tc.launch(() {
    tc.group("- Squadron Worker", () {
      tc.group('- start/stop/terminate', () {
        tc.test('- start & stop', () async {
          await TestWorker(tc).useAsync((w) async {
            expect(w.isConnected, isFalse);
            expect(w.upTime, Duration.zero);
            expect(w.idleTime, Duration.zero);
            expect(w.isStopped, isFalse);

            final channel = await w.start();
            expect(channel, isNotNull);
            expect(w.isConnected, isTrue);

            await Future.delayed(TestDelays.delay * 2);
            expect(w.upTime, greaterThanOrEqualTo(TestDelays.delay));
            expect(w.isStopped, isFalse);
            expect(w.idleTime, lessThanOrEqualTo(w.upTime));

            w.stop();
            expect(w.isStopped, isTrue);
            final upTime = w.upTime;
            expect(w.isConnected, isFalse);
            expect(w.upTime, greaterThan(Duration.zero));

            await Future.delayed(TestDelays.delay);
            expect(w.upTime, upTime);
            expect(w.idleTime, greaterThanOrEqualTo(TestDelays.delay));
          });
        });

        tc.test('- start & terminate - sync', () async {
          await TestWorker(tc).useAsync((w) async {
            expect(w.isConnected, isFalse);
            expect(w.upTime, Duration.zero);
            expect(w.idleTime, Duration.zero);
            expect(w.isStopped, isFalse);

            final channel = await w.start();
            expect(channel, isNotNull);
            expect(w.isConnected, isTrue);

            await Future.delayed(TestDelays.delay * 2);
            expect(w.upTime, greaterThanOrEqualTo(TestDelays.delay));
            expect(w.isStopped, isFalse);
            expect(w.idleTime, lessThanOrEqualTo(w.upTime));

            final duration = TestDelays.delay * 6;
            Future.delayed(duration * 0.5, () {
              w.terminate();
              expect(w.isStopped, isTrue);
            });

            try {
              await w.cpu(ms: duration.inMilliseconds);
              throw unexpectedSuccess('cpu completed after termination');
            } on TaskTerminatedException {
              // expected: the "cpu" task has been terminated
            }

            expect(w.isStopped, isTrue);
            final upTime = w.upTime;
            expect(w.isConnected, isFalse);
            expect(w.upTime, greaterThan(Duration.zero));

            await Future.delayed(TestDelays.delay);
            expect(w.upTime, upTime);
            expect(w.idleTime, greaterThanOrEqualTo(TestDelays.delay));
          });
        });

        tc.test('- start & terminate - async', () async {
          await TestWorker(tc).useAsync((w) async {
            expect(w.isConnected, isFalse);
            expect(w.upTime, Duration.zero);
            expect(w.idleTime, Duration.zero);
            expect(w.isStopped, isFalse);

            final channel = await w.start();
            expect(channel, isNotNull);
            expect(w.isConnected, isTrue);

            await Future.delayed(TestDelays.delay * 2);
            expect(w.upTime, greaterThanOrEqualTo(TestDelays.delay));
            expect(w.isStopped, isFalse);
            expect(w.idleTime, lessThanOrEqualTo(w.upTime));

            final duration = TestDelays.delay * 6;
            Future.delayed(duration * 0.5, () {
              w.terminate();
              expect(w.isStopped, isTrue);
            });

            try {
              await w.io(ms: duration.inMilliseconds);
              throw unexpectedSuccess('io completed after termination');
            } on TaskTerminatedException {
              // expected: the "io" task has been terminated
            }

            expect(w.isStopped, isTrue);
            final upTime = w.upTime;
            expect(w.isConnected, isFalse);
            expect(w.upTime, greaterThan(Duration.zero));

            await Future.delayed(TestDelays.delay);
            expect(w.upTime, upTime);
            expect(w.idleTime, greaterThanOrEqualTo(TestDelays.delay));
          });
        });

        tc.test('- hook', () async {
          String? status;
          void hook(PlatformThread pw) {
            status = 'hook called';
          }

          await TestWorker(tc, hook: hook).useAsync((w) async {
            expect(status, isNull);
            await w.start();
            expect(status, matches('hook called'));
          });
        });

        tc.test('- hook failure', () async {
          String? status;
          void hook(PlatformThread pw) {
            status = 'hook called';
            throw CustomException('intended exception after setting status');
          }

          await TestWorker(tc, hook: hook).useAsync((w) async {
            expect(status, isNull);
            try {
              final res = await w.start();
              throw unexpectedSuccess('start', res);
            } on CustomException catch (ex) {
              expect(status, matches('hook called'));
              expect(ex, reports('intended exception'));
            }
          });
        });

        tc.group('- install', () {
          tc.test('- no error', () async {
            await InstallableWorker(tc).useAsync((w) async {
              final logger = MemoryLogger();
              logger.level = Level.all;
              w.channelLogger = logger;
              await w.start();

              expect(await w.isInstalled(), isTrue);
              expect(await w.isUninstalled(), isFalse);

              // log forwarding is asynchronous, make sure they have time to arrive
              await Future.delayed(TestDelays.shortDelay);
              expect(logger.logs, mentions('service installed'));
              expect(logger.logs, doesNotMention('intended failure'));

              // stopping the worker uninstalls the service
              w.stop();

              // log forwarding is asynchronous, make sure they have time to arrive
              await Future.delayed(TestDelays.shortDelay);
              expect(logger.logs, mentions('service uninstalled'));
              expect(logger.logs, doesNotMention('intended failure'));
            });
          });

          tc.test('- error on installation', () async {
            await InstallableWorker.throwOnInstall(tc).useAsync((w) async {
              final logger = MemoryLogger();
              w.channelLogger = logger;
              await w.start();

              try {
                final res = await w.isInstalled();
                throw unexpectedSuccess('isInstalled()', res);
              } on WorkerException catch (ex) {
                expect(ex, reports('this exception is reported'));
                // log forwarding is asynchronous, make sure they have time to arrive
                await Future.delayed(TestDelays.shortDelay);
                expect(logger.logs, doesNotMention('service installed'));
              }
            });
          });

          tc.test('- error on uninstallation', () async {
            await InstallableWorker.throwOnUninstall(tc).useAsync((w) async {
              final logger = MemoryLogger();
              w.channelLogger = logger;
              await w.start();

              // log forwarding is asynchronous, make sure they have time to arrive
              await Future.delayed(TestDelays.shortDelay);
              expect(logger.logs, mentions('service installed'));
              expect(logger.logs, doesNotMention('intended failure'));

              expect(await w.isInstalled(), isTrue);
              expect(await w.isUninstalled(), isFalse);

              // stopping the worker uninstalls the service
              w.stop();

              // log forwarding is asynchronous, make sure they have time to arrive
              await Future.delayed(TestDelays.shortDelay);
              expect(logger.logs, mentions('intended failure'));
              expect(logger.logs, doesNotMention('service uninstalled'));
            });
          });
        });

        tc.test('- cannot restart after stop', () async {
          await TestWorker(tc).useAsync((w) async {
            await w.start();
            expect(w.isStopped, isFalse);

            await Future.delayed(TestDelays.delay);

            w.stop();
            expect(w.isStopped, isTrue);

            await Future.delayed(TestDelays.delay);

            try {
              final res = await w.start();
              throw unexpectedSuccess('start()', res);
            } on WorkerException catch (ex) {
              expect(ex, reports('worker is stopped'));
            }
          });
        });
      });

      tc.group('- workloads', () {
        tc.test('- platform type', () async {
          await TestWorker(tc).useAsync((w) async {
            // make sure platforms match with the test context
            expect(Squadron.platformType, tc.clientPlatform);
            final workerPlatform = await w.getPlatformType();
            expect(workerPlatform, tc.workerPlatform);
          });
        });

        tc.test('- maps', () async {
          await TestWorker(tc).useAsync((w) async {
            final input = {
              BigInt.one.toString(): BigInt.one,
              BigInt.two.toString(): BigInt.two,
            };
            final res = await w.map(input);
            expect(res, {
              BigInt.one: BigInt.one.toString(),
              BigInt.two: BigInt.two.toString(),
            });
          });
        });

        tc.test('- sequential', () async {
          await TestWorker(tc).useAsync((w) async {
            int taskId = 0;
            final completedTasks = <int>[];
            Future createTask(Duration duration) {
              final id = ++taskId;
              return w
                  .io(ms: duration.inMilliseconds)
                  .whenComplete(() => completedTasks.add(id));
            }

            expect(w.workload, isZero);
            expect(w.maxWorkload, isZero);
            expect(w.totalWorkload, isZero);

            await createTask(TestDelays.delay); // task #1

            expect(completedTasks, contains(1)); // #1 has completed
            expect(w.workload, isZero);
            expect(w.maxWorkload, 1);
            expect(w.totalWorkload, 1);

            final task = createTask(TestDelays.delay * 3); // task #2

            expect(completedTasks, contains(1)); // #2 is pending
            expect(w.workload, 1);
            expect(w.maxWorkload, 1);
            expect(w.totalWorkload, 1);

            await Future.delayed(TestDelays.delay);

            expect(completedTasks, contains(1)); // #2 is still pending
            expect(w.workload, 1);
            expect(w.maxWorkload, 1);
            expect(w.totalWorkload, 1);

            await task;

            expect(completedTasks, containsAll([1, 2])); // #2 has completed
            expect(w.workload, isZero);
            expect(w.maxWorkload, 1);
            expect(w.totalWorkload, 2);

            await createTask(TestDelays.delay); // task #3

            expect(completedTasks, containsAll([1, 2, 3])); // #3 has completed
            expect(w.workload, isZero);
            expect(w.maxWorkload, 1);
            expect(w.totalWorkload, 3);

            w.stop();

            expect(w.workload, isZero);
            expect(w.maxWorkload, 1);
            expect(w.totalWorkload, 3);
            expect(w.upTime, greaterThanOrEqualTo(TestDelays.delay * 5));
          });
        });

        tc.test('- parallel', () async {
          await TestWorker(tc).useAsync((w) async {
            int taskId = 0;
            final completedTasks = <int>[];
            Future createTask(Duration duration) {
              final id = ++taskId;
              return w
                  .io(ms: duration.inMilliseconds + 50)
                  .whenComplete(() => completedTasks.add(id));
            }

            await w.start();

            expect(w.workload, isZero);
            expect(w.maxWorkload, isZero);
            expect(w.totalWorkload, isZero);

            var tasks = [
              createTask(TestDelays.delay), // task 1
              createTask(TestDelays.delay * 5), // task 2
              createTask(TestDelays.delay * 3), // task 3
            ];

            expect(completedTasks, isEmpty);
            expect(w.workload, 3);
            expect(w.maxWorkload, 3);
            expect(w.totalWorkload, isZero);

            await Future.wait(tasks);

            // all tasks have completed
            expect(completedTasks, containsAll([1, 2, 3]));
            expect(w.workload, isZero);
            expect(w.maxWorkload, 3);
            expect(w.totalWorkload, 3);
            expect(w.upTime, greaterThanOrEqualTo(TestDelays.delay * 5));
            expect(w.upTime, lessThanOrEqualTo(TestDelays.delay * 7));

            /////////// time origin for next tasks ///////////

            completedTasks.clear();
            createTask(TestDelays.delay * 9); // #4 complete at ~9 delays
            createTask(TestDelays.delay * 5); // #5 complete at ~5 delays
            createTask(TestDelays.delay * 3); // #6 complete at ~3 delays

            expect(completedTasks, isEmpty);
            expect(w.workload, 3);
            expect(w.maxWorkload, 3);
            expect(w.totalWorkload, 3);

            // 1 delay: all tasks still pending
            await Future.delayed(TestDelays.delay);
            expect(completedTasks, isEmpty);
            expect(w.workload, 3);
            expect(w.maxWorkload, 3);
            expect(w.totalWorkload, 3);

            // 4 delays: #6 has completed
            await Future.delayed(TestDelays.delay * 3);
            expect(completedTasks, contains(6));
            expect(w.workload, 2);
            expect(w.maxWorkload, 3);
            expect(w.totalWorkload, 4);

            createTask(TestDelays.delay * 5); // #7 completes at ~9 delays
            createTask(TestDelays.delay * 3); // #8 completes at ~7 delays

            expect(completedTasks, contains(6));
            expect(w.workload, 4);
            expect(w.maxWorkload, 4);
            expect(w.totalWorkload, 4);

            // 8 delays: #5 and #8 have completed
            await Future.delayed(TestDelays.delay * 4);
            expect(completedTasks, containsAll([5, 6, 8]));
            expect(w.workload, 2);
            expect(w.maxWorkload, 4);
            expect(w.totalWorkload, 6);

            // 11 delays: all tasks have completed
            await Future.delayed(TestDelays.delay * 3);
            expect(completedTasks, containsAll([4, 5, 6, 7, 8]));
            expect(w.workload, isZero);
            expect(w.maxWorkload, 4);
            expect(w.totalWorkload, 8);

            w.stop();
            expect(w.workload, isZero);
            expect(w.maxWorkload, 4);
            expect(w.totalWorkload, 8);
            expect(w.upTime, greaterThanOrEqualTo(TestDelays.delay * 16));
            expect(w.upTime, lessThan(TestDelays.delay * 19));
          });
        });
      });
    });
  });
}
