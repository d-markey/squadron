// ignore_for_file: file_names

@TestOn('vm || browser')
library;

import 'package:squadron/squadron.dart';
import 'package:test/test.dart';
import 'package:using/using.dart';

import 'classes/custom_exception.dart';
import 'classes/platform.dart';
import 'classes/test_context.dart';
import 'classes/utils.dart';
import 'worker_services/error_service.dart';
import 'worker_services/error_service_worker.dart';
import 'worker_services/missing_worker_service.dart';

Future<void> main() => TestContext.run(execute);

const testScript = '05_worker_errors_test.dart';

void execute(TestContext? tc) {
  if (tc == null) return;

  tc.launch(() {
    tc.group("- Squadron Worker", () {
      tc.group('- initialization error', () {
        tc.test('- not found', () async {
          await MissingWorker(tc).useAsync((w) async {
            await expectLater(w.start(), failsWith<SquadronError>());
          });
        }, skip: tc.entryPoints.missingWorker == null);

        tc.test('- failed init', () async {
          await ErrorWorker.throws(tc).useAsync((w) async {
            await expectLater(w.start(), failsWith<WorkerException>());
            await expectLater(w.ping(), failsWith<WorkerException>());
          });
        });

        tc.test('- missing start request', () async {
          await ErrorWorker.missingStartRequest(tc).useAsync((w) async {
            await expectLater(w.start(), failsWith<SquadronError>());
            await expectLater(w.ping(), failsWith<SquadronError>());
          });
        }, skip: tc.entryPoints.missingStartRequest == null);

        tc.test('- invalid command ID', () async {
          await ErrorWorker.invalid(tc).useAsync((w) async {
            await expectLater(w.start(), failsWith<SquadronError>());
            await expectLater(w.ping(), failsWith<SquadronError>());
          });
        });
      });

      tc.group('- error handling', () {
        late final ErrorWorker worker;

        tc.setUpAll(() async {
          worker = ErrorWorker(tc);
          await worker.start();
        });

        tc.tearDownAll(() {
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
            expect(ex, reports('Failed to deserialize'));
            expect(ex, reports('CUSTOM'));
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
              expect(ex.command, ErrorService.throwCustomExceptionCommand);
            }
            expect(worker.stats.totalErrors, errors + 1);
          } finally {
            worker.exceptionManager.unregister(CustomException.typeId);
          }
        });

        tc.test('- invalid request', () async {
          expect(await worker.ping([1]), isTrue);

          try {
            final res = await worker.ping(unsendable);
            throw unexpectedSuccess('ping()', res);
          } on SquadronError catch (ex) {
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
            await worker.missing();
            throw unexpectedSuccess('missing()', null);
          } on SquadronError catch (ex) {
            expect(ex, reports(('Unknown command')));
          }

          // ensure worker is still alive
          expect(await worker.ping(), isTrue);
        });
      });
    });
  });
}
