// ignore_for_file: file_names

@TestOn('vm || browser')
library;

import 'dart:async';

import 'package:logger/logger.dart';
import 'package:squadron/squadron.dart';
import 'package:test/test.dart';
import 'package:using/using.dart';

import 'classes/custom_exception.dart';
import 'classes/memory_logger.dart';
import 'classes/platform.dart';
import 'classes/test_context.dart';
import 'classes/utils.dart';
import 'worker_services/delays.dart';
import 'worker_services/installable_service_worker.dart';
import 'worker_services/missing_worker_service.dart';
import 'worker_services/test_service.dart';
import 'worker_services/test_service_worker.dart';

void main() async {
  final testContext = await TestContext.init('');
  execute(testContext);
}

String testScript = '03_worker_test.dart';

void execute(TestContext tc) {
  tc.run(() {
    tc.group("- Squadron Worker", () {
      tc.group('- start/stop', () {
        final logs = <String>[];
        final memoryLogger = MemoryLogger(logs);

        setUp(() {
          memoryLogger.clear();
          memoryLogger.level = Level.all;
        });

        tearDown(() {
          memoryLogger.clear();
        });

        tc.test('- start & stop', () {
          return TestWorker(tc).useAsync((w) async {
            w.channelLogger = memoryLogger;

            expect(w.channel, isNull);
            expect(w.upTime, Duration.zero);
            expect(w.idleTime, Duration.zero);
            expect(w.isStopped, isFalse);

            final channel = await w.start();
            expect(w.channel, isNotNull);
            expect(channel, w.channel);

            await Future.delayed(TestDelays.delay);
            expect(w.upTime, greaterThanOrEqualTo(TestDelays.delay));
            expect(w.isStopped, isFalse);
            expect(w.idleTime, greaterThanOrEqualTo(w.upTime));

            w.stop();
            expect(w.isStopped, isTrue);
            final upTime = w.upTime;
            expect(w.channel, isNull);
            expect(w.upTime, greaterThan(Duration.zero));

            await Future.delayed(TestDelays.delay);
            expect(w.upTime, upTime);
            expect(w.idleTime, greaterThan(w.upTime));
          });
        });

        tc.test('- hook', () async {
          String? status;
          void hook(PlatformThread pw) {
            status = 'hook called';
          }

          await TestWorker(tc, hook).useAsync((w) async {
            w.channelLogger = memoryLogger;
            expect(status, isNull);
            await w.start();
            expect(status, matches('hook called'));
            expect(logs, mentions(''));
          });
        });

        tc.test('- hook failure', () async {
          String? status;
          void hook(PlatformThread pw) {
            status = 'hook called';
            throw CustomException('intended exception after setting status');
          }

          await TestWorker(tc, hook).useAsync((w) async {
            w.channelLogger = memoryLogger;
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
              w.channelLogger = memoryLogger;
              await w.start();
              expect(logs, doesNotMention('intended failure'));
              expect(logs, mentions('service installed'));

              expect(await w.isInstalled(), isTrue);
              expect(await w.isUninstalled(), isFalse);

              // stopping the worker uninstalls the service
              w.stop();

              await Future.delayed(TestDelays.delay * 1.5);
              expect(logs, mentions('service uninstalled'));
              expect(logs, doesNotMention('intended failure'));
            });
          });

          tc.test('- error on installation', () async {
            await InstallableWorker.throwOnInstall(tc).useAsync((w) async {
              w.channelLogger = memoryLogger;
              try {
                final res = await w.start();
                throw unexpectedSuccess('start()', res);
              } on WorkerException catch (ex) {
                expect(ex, reports('this exception is reported'));
                expect(logs, mentions('intended failure'));
                expect(logs, doesNotMention('service installed'));
              }

              try {
                final res = await w.isInstalled();
                throw unexpectedSuccess('isInstalled()', res);
              } on WorkerException catch (ex) {
                expect(ex, reports('this exception is reported'));
                expect(logs, doesNotMention('service installed'));
              }
            });
          });

          tc.test('- error on uninstallation', () async {
            await InstallableWorker.throwOnUninstall(tc).useAsync((w) async {
              w.channelLogger = memoryLogger;
              await w.start();
              expect(logs, doesNotMention('intended failure'));
              expect(logs, mentions('service installed'));

              expect(await w.isInstalled(), isTrue);
              expect(await w.isUninstalled(), isFalse);

              // stopping the worker uninstalls the service
              w.stop();

              await Future.delayed(TestDelays.delay * 1.5);
              expect(logs, mentions('intended failure'));
              expect(logs, doesNotMention('service uninstalled'));
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

      tc.group('- initialization error', () {
        tc.test('- not found', () async {
          await MissingWorker(tc).useAsync((w) async {
            await expectLater(w.start(), failsWith<SquadronError>());
          });
        }, skip: tc.entryPoints.missingWorker == null);

        tc.test('- failed init', () async {
          await TestWorker.throws(tc).useAsync((w) async {
            await expectLater(w.start(), failsWith<WorkerException>());
            await expectLater(w.ping(), failsWith<WorkerException>());
          });
        });

        tc.test('- missing start request', () async {
          await TestWorker.missingStartRequest(tc).useAsync((w) async {
            await expectLater(w.start(), failsWith<SquadronError>());
            await expectLater(w.ping(), failsWith<SquadronError>());
          });
        }, skip: tc.entryPoints.missingStartRequest == null);

        tc.test('- invalid command ID', () async {
          await TestWorker.invalid(tc).useAsync((w) async {
            await expectLater(w.start(), failsWith<SquadronError>());
            await expectLater(w.ping(), failsWith<SquadronError>());
          });
        });
      });

      tc.group('- workloads', () {
        tc.test('- sequential', () async {
          await TestWorker(tc).useAsync((w) async {
            await w.start();

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

            expect(completedTasks, [1]); // #1 has completed
            expect(w.workload, isZero);
            expect(w.maxWorkload, 1);
            expect(w.totalWorkload, 1);

            final task = createTask(TestDelays.delay * 3); // task #2

            expect(completedTasks, [1]); // #2 is pending
            expect(w.workload, 1);
            expect(w.maxWorkload, 1);
            expect(w.totalWorkload, 1);

            await Future.delayed(TestDelays.delay);

            expect(completedTasks, [1]); // #2 is still pending
            expect(w.workload, 1);
            expect(w.maxWorkload, 1);
            expect(w.totalWorkload, 1);

            await task;

            expect(completedTasks, [1, 2]); // #2 has completed
            expect(w.workload, isZero);
            expect(w.maxWorkload, 1);
            expect(w.totalWorkload, 2);

            await createTask(TestDelays.delay); // task #3

            expect(completedTasks, [1, 2, 3]); // #3 has completed
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
                  .io(ms: duration.inMilliseconds)
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
            expect(completedTasks, {1, 2, 3});
            expect(w.workload, isZero);
            expect(w.maxWorkload, 3);
            expect(w.totalWorkload, 3);
            expect(w.upTime, greaterThanOrEqualTo(TestDelays.delay * 5));
            expect(w.upTime, lessThan(TestDelays.delay * 7));

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
            expect(completedTasks, {6});
            expect(w.workload, 2);
            expect(w.maxWorkload, 3);
            expect(w.totalWorkload, 4);

            createTask(TestDelays.delay * 5); // #7 completes at ~9 delays
            createTask(TestDelays.delay * 3); // #8 completes at ~7 delays

            expect(completedTasks, {6});
            expect(w.workload, 4);
            expect(w.maxWorkload, 4);
            expect(w.totalWorkload, 4);

            // 8 delays: #5 and #8 have completed
            await Future.delayed(TestDelays.delay * 4);
            expect(completedTasks, {5, 6, 8});
            expect(w.workload, 2);
            expect(w.maxWorkload, 4);
            expect(w.totalWorkload, 6);

            // 11 delays: all tasks have completed
            await Future.delayed(TestDelays.delay * 3);
            expect(completedTasks, {4, 5, 6, 7, 8});
            expect(w.workload, isZero);
            expect(w.maxWorkload, 4);
            expect(w.totalWorkload, 8);

            w.stop();
            expect(w.workload, isZero);
            expect(w.maxWorkload, 4);
            expect(w.totalWorkload, 8);
            expect(w.upTime, greaterThanOrEqualTo(TestDelays.delay * 16));
            expect(w.upTime, lessThan(TestDelays.delay * 18));
          });
        });

        tc.group('- error handling', () {
          late final TestWorker worker;

          setUpAll(() {
            worker = TestWorker(tc);
            return worker.start();
          });

          tearDownAll(() {
            worker.stop();
          });

          tc.test('- Exception', () async {
            final errors = worker.stats.totalErrors;
            try {
              final res = await worker.throwException();
              throw unexpectedSuccess('throwException()', res);
            } on WorkerException catch (ex) {
              expect(ex, reports('intentional exception'));
              expect(ex.stackTrace, hasCalled('throwException'));
            }
            expect(worker.stats.totalErrors, errors + 1);
          });

          tc.test('- WorkerException', () async {
            final errors = worker.stats.totalErrors;
            try {
              final res = await worker.throwWorkerException();
              throw unexpectedSuccess('throwWorkerException()', res);
            } on WorkerException catch (ex) {
              expect(ex, reports('intentional worker exception'));
              expect(ex.stackTrace, hasCalled('throwWorkerException'));
            }
            expect(worker.stats.totalErrors, errors + 1);
          });

          tc.test('- TaskTimeOutException', () async {
            final errors = worker.stats.totalErrors;
            try {
              final res = await worker.throwTaskTimeOutException();
              throw unexpectedSuccess('throwTaskTimeOutException()', res);
            } on SquadronTimeoutException catch (ex) {
              expect(ex, reports('intentional timeout exception'));
            }
            expect(worker.stats.totalErrors, errors + 1);
          });

          tc.test('- CanceledException', () async {
            final errors = worker.stats.totalErrors;
            try {
              final res = await worker.throwCanceledException();
              throw unexpectedSuccess('throwCanceledException()', res);
            } on SquadronCanceledException catch (ex) {
              expect(ex, reports('intentional canceled exception'));
            }
            expect(worker.stats.totalErrors, errors + 1);
          });

          tc.test('- CustomException (unregistered)', () async {
            final errors = worker.stats.totalErrors;
            try {
              final res = await worker.throwCustomException();
              throw unexpectedSuccess('throwCustomException()', res);
            } on WorkerException catch (ex) {
              expect(ex, isNotA<CustomException>());
              expect(ex, reports('Missing deserializer for CUSTOM'));
            }
            expect(worker.stats.totalErrors, errors + 1);
          });

          tc.test('- CustomException (registered)', () async {
            try {
              worker.exceptionManager.register(
                CustomException.typeId,
                CustomException.deserialize,
              );
              final errors = worker.stats.totalErrors;
              try {
                final res = await worker.throwCustomException();
                throw unexpectedSuccess('throwCustomException()', res);
              } on CustomException catch (ex) {
                expect(ex, reports('intentional CUSTOM exception'));
                expect(ex.stackTrace, hasCalled('throwCustomException'));
                expect(ex.command, TestService.throwCustomExceptionCommand);
              }
              expect(worker.stats.totalErrors, errors + 1);
            } finally {
              worker.exceptionManager.unregister(CustomException.typeId);
            }
          });

          tc.test('- invalid request', () async {
            final list = [1];
            expect(await worker.forward(list), list);

            try {
              final res = await worker.forward(getUnsendable());
              throw unexpectedSuccess('forward()', res);
            } on WorkerException catch (ex) {
              expect(ex, reports('Failed to post request'));
            }

            // ensure worker is still alive
            expect(await worker.ping(), isTrue);
          });

          tc.test('- invalid response', () async {
            try {
              final res = await worker.invalidResponse();
              throw unexpectedSuccess('invalidResponse()', res);
            } on SquadronError catch (ex) {
              expect(ex, reports('Failed to post response'));
            }

            // ensure worker is still alive
            expect(await worker.ping(), isTrue);
          });

          tc.test('- missing operation', () async {
            try {
              final res = await worker.missing();
              throw unexpectedSuccess('missing()', res);
            } on SquadronError catch (ex) {
              expect(ex, reports(('Unknown command')));
            }

            // ensure worker is still alive
            expect(await worker.ping(), isTrue);
          });
        });
      });
    });
  });
}
