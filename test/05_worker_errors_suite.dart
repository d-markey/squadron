// ignore_for_file: file_names

import 'package:squadron/squadron.dart';
import 'package:test/test.dart';

import 'src/memory_logger.dart';
import 'src/platform.dart';
import 'src/test_context.dart';
import 'src/utils.dart';
import 'test_delay.dart';
import 'test_exception.dart';
import 'test_extensions.dart';
import 'worker_services/error_service.dart';
import 'worker_services/error_service_worker.dart';
import 'worker_services/installable_service_worker.dart';
import 'worker_services/missing_worker_service.dart';
import 'worker_services/test_service_worker.dart';

Future<void> main() => TestContext.run(execute);

const testScript = '05_worker_errors_test.dart';

void execute(TestContext? tc) {
  if (tc == null) return;

  tc.launch(() {
    tc.group('- SQUADRON WORKER - ERRORS', () {
      tc.test(
          '- Missing worker',
          () => MissingWorker(tc).runTest((w) async {
                await expectLater(w.start(), failsWith<SquadronError>());
              }),
          skip: tc.entryPoints.missingWorker == null);

      tc.test(
          '- Failed initialization',
          () => ErrorWorker.throws(tc).runTest((w) async {
                await expectLater(w.start(), failsWith<WorkerException>());
                await expectLater(w.ping(), failsWith<WorkerException>());
              }));

      tc.test(
          '- Missing start request',
          () => ErrorWorker.missingStartRequest(tc).runTest((w) async {
                await expectLater(w.start(), failsWith<SquadronError>());
                await expectLater(w.ping(), failsWith<SquadronError>());
              }),
          skip: tc.entryPoints.missingStartRequest == null);

      tc.test(
          '- Invalid command ID',
          () => ErrorWorker.invalid(tc).runTest((w) async {
                await expectLater(w.start(), failsWith<SquadronError>());
                await expectLater(w.ping(), failsWith<SquadronError>());
              }));

      tc.test('- Failed hook installation', () async {
        String? status;
        void hook(PlatformThread pw) {
          status = 'hook called';
          throw TestException('intended exception after setting status');
        }

        await TestWorker(tc, hook: hook).runTest((w) async {
          expect(status, isNull);
          try {
            final res = await w.start();
            throw unexpectedSuccess('start', res);
          } on TestException catch (ex) {
            expect(status, matches('hook called'));
            expect(ex, reports('intended exception'));
          }
        });
      });

      tc.test(
          '- Failed service installation',
          () => InstallableWorker.throwOnInstall(tc).runTest((w) async {
                final logger = MemoryLogger();
                w.channelLogger = logger;
                await w.start();

                try {
                  final res = await w.isInstalled();
                  throw unexpectedSuccess('isInstalled()', res);
                } on WorkerException catch (ex) {
                  expect(ex, reports('this exception is reported'));
                  // log forwarding is asynchronous, make sure they have time to arrive
                  await Future.delayed(TestDelay.tick);
                  expect(logger.logs, doesNotMention('service installed'));
                }
              }));

      tc.test(
          '- Failed service uninstallation',
          () => InstallableWorker.throwOnUninstall(tc).runTest((w) async {
                final logger = MemoryLogger();
                w.channelLogger = logger;
                await w.start();

                // log forwarding is asynchronous, make sure they have time to arrive
                await Future.delayed(TestDelay.tick);
                expect(logger.logs, mentions('service installed'));
                expect(logger.logs, doesNotMention('intended failure'));

                expect(await w.isInstalled(), isTrue);
                expect(await w.isUninstalled(), isFalse);

                // stopping the worker uninstalls the service
                w.stop();

                // log forwarding is asynchronous, make sure they have time to arrive
                await Future.delayed(TestDelay.tick);
                expect(logger.logs, mentions('intended failure'));
                expect(logger.logs, doesNotMention('service uninstalled'));
              }));

      tc.test(
          '- Dart Exception',
          () => ErrorWorker(tc).startAndRunTest((w) async {
                final errors = w.totalErrors;
                try {
                  final res = await w.throwException();
                  throw unexpectedSuccess('throwException()', res);
                } on WorkerException catch (ex) {
                  expect(ex, reports('intentional exception'));
                  expect(ex.stackTrace, hasCalled('throwException'));
                }
                expect(w.totalErrors, errors + 1);
              }));

      tc.test(
          '- WorkerException',
          () => ErrorWorker(tc).startAndRunTest((w) async {
                final errors = w.totalErrors;
                try {
                  final res = await w.throwWorkerException();
                  throw unexpectedSuccess('throwWorkerException()', res);
                } on WorkerException catch (ex) {
                  expect(ex, reports('intentional worker exception'));
                  expect(ex.stackTrace, hasCalled('throwWorkerException'));
                }
                expect(w.totalErrors, errors + 1);
              }));

      tc.test(
          '- TaskTimeOutException',
          () => ErrorWorker(tc).startAndRunTest((w) async {
                final errors = w.totalErrors;
                try {
                  final res = await w.throwTaskTimeOutException();
                  throw unexpectedSuccess('throwTaskTimeOutException()', res);
                } on SquadronTimeoutException catch (ex) {
                  expect(ex, reports('intentional timeout exception'));
                }
                expect(w.totalErrors, errors + 1);
              }));

      tc.test(
          '- CanceledException',
          () => ErrorWorker(tc).startAndRunTest((w) async {
                final errors = w.totalErrors;
                try {
                  final res = await w.throwCanceledException();
                  throw unexpectedSuccess('throwCanceledException()', res);
                } on SquadronCanceledException catch (ex) {
                  expect(ex, reports('intentional canceled exception'));
                }
                expect(w.totalErrors, errors + 1);
              }));

      tc.test(
          '- TestException (unregistered)',
          () => ErrorWorker(tc).startAndRunTest((w) async {
                final errors = w.totalErrors;
                try {
                  final res = await w.throwTestException();
                  throw unexpectedSuccess('throwTestException()', res);
                } on WorkerException catch (ex) {
                  expect(ex, isNotA<TestException>());
                  expect(ex, reports('Failed to deserialize'));
                  expect(ex, reports('#TEST'));
                }
                expect(w.totalErrors, errors + 1);
              }));

      tc.test(
          '- TestException (registered)',
          () => ErrorWorker(tc).startAndRunTest((w) async {
                try {
                  w.exceptionManager.register(
                    TestException.typeId,
                    TestException.deserialize,
                  );
                  final errors = w.totalErrors;
                  try {
                    final res = await w.throwTestException();
                    throw unexpectedSuccess('throwTestException()', res);
                  } on TestException catch (ex) {
                    expect(ex, reports('intentional TEST exception'));
                    expect(ex.stackTrace, hasCalled('throwTestException'));
                    expect(ex.command, ErrorService.throwTestExceptionCommand);
                  }
                  expect(w.totalErrors, errors + 1);
                } finally {
                  w.exceptionManager.unregister(TestException.typeId);
                }
              }));

      tc.test(
          '- Invalid request',
          () => ErrorWorker(tc).startAndRunTest((w) async {
                expect(await w.ping([1]), isTrue);

                try {
                  final res = await w.ping(unsendable);
                  throw unexpectedSuccess('ping()', res);
                } on SquadronError catch (ex) {
                  expect(ex, reports('Failed to post request'));
                }

                // ensure worker is still alive
                expect(await w.ping(), isTrue);
              }));

      tc.test(
          '- Invalid response',
          () => ErrorWorker(tc).startAndRunTest((w) async {
                try {
                  final res = await w.invalidResponse();
                  throw unexpectedSuccess('invalidResponse()', res);
                } on SquadronError catch (ex) {
                  expect(ex, reports('Failed to post response'));
                }

                // ensure worker is still alive
                expect(await w.ping(), isTrue);
              }));

      tc.test(
          '- Missing operation',
          () => ErrorWorker(tc).startAndRunTest((w) async {
                try {
                  await w.missing();
                  throw unexpectedSuccess('missing()', null);
                } on SquadronError catch (ex) {
                  expect(ex, reports(('Unknown command')));
                }

                // ensure worker is still alive
                expect(await w.ping(), isTrue);
              }));
    });
  });
}
