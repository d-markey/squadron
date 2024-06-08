@TestOn('vm || browser')
library;

import 'package:squadron/squadron.dart';
import 'package:test/test.dart';

import 'classes/platform.dart';
import 'classes/test_context.dart';
import 'classes/utils.dart';
import 'worker_services/local_client_worker.dart';
import 'worker_services/local_workers/local_service.dart';

void main() async {
  final testContext = await TestContext.init('');
  execute(testContext);
}

void execute(TestContext testContext) => testContext.run(() {
      group("- LocalWorker", () {
        setUpAll(() {});

        tearDownAll(() {});

        group('- Identity', () {
          test('- LocalWorker', () async {
            final localService = LocalServiceImpl();
            var id = localService.getId();
            expect(id, equals('LocalWorker running as "$threadId"'));

            final localWorker = LocalWorker.create(localService);
            try {
              final id = await localWorker.channel
                  ?.sendRequest(LocalService.getIdCommand, []);
              expect(id, equals('LocalWorker running as "$threadId"'));
            } finally {
              localWorker.stop();
            }
          });

          test('- Squadron Worker', () async {
            final localService = LocalServiceImpl();
            final localWorker = LocalWorker.create(localService);

            try {
              final localClientWorker = LocalClientWorker(
                testContext,
                args: [localWorker.channel?.share().serialize()],
              );
              final check = await localClientWorker.checkIds();

              final regExp = RegExp(
                  'Worker running as "(0x[0-9A-Fa-f]+)", LocalWorker running as "(0x[0-9A-Fa-f]+)"');
              final match = regExp.firstMatch(check);
              expect(match, isNotNull);
              expect(match!.group(1), isNot(equals(match.group(2))));
            } finally {
              localWorker.stop();
            }
          });

          test('- WorkerPool', () async {
            final localService = LocalServiceImpl();
            final localWorker = LocalWorker.create(localService);

            try {
              final localClientWorkerPool = LocalClientWorkerPool(
                  testContext,
                  localWorker,
                  ConcurrencySettings(
                      minWorkers: 2, maxWorkers: 4, maxParallel: 3));

              final tasks = <Future<String>>[];

              for (var i = 0;
                  i <
                      localClientWorkerPool.concurrencySettings.maxParallel *
                          localClientWorkerPool.concurrencySettings.maxWorkers;
                  i++) {
                tasks.add(localClientWorkerPool.checkIds());
              }

              final results = await Future.wait(tasks);

              final workerIds = <String>{};
              final regExp = RegExp(
                  'Worker running as "(0x[0-9A-Fa-f]+)", LocalWorker running as "(0x[0-9A-Fa-f]+)"');
              for (var result in results) {
                expect(result, matches(regExp));
                final match = regExp.firstMatch(result)!;
                final wid = match.group(1);
                expect(wid, isNotNull);
                expect(wid, isNot(equals(threadId)));
                expect(match.group(2), equals(threadId));
                workerIds.add(wid!);
              }
            } finally {
              localWorker.stop();
            }
          });
        });

        group('- Exception', () {
          test('- LocalWorker', () async {
            final localService = LocalServiceImpl();
            try {
              final res = localService.throwException();
              throw unexpectedSuccess('throwException()', res);
            } catch (ex) {
              lowerCaseCheck(ex, contains('intentional exception'));
            }

            final localWorker = LocalWorker.create(localService);
            try {
              final res = await localWorker.channel
                  ?.sendRequest(LocalService.throwExceptionCommand, []);
              throw unexpectedSuccess('throwException()', res);
            } on WorkerException catch (ex) {
              lowerCaseCheck(ex.message, contains('intentional exception'));
              caseCheck(ex.stackTrace, contains('throwException'));
            }
          });

          test('- Squadron Worker', () async {
            final localService = LocalServiceImpl();
            final localWorker = LocalWorker.create(localService);

            try {
              final localClientWorker = LocalClientWorker(testContext,
                  args: [localWorker.channel?.share().serialize()]);
              final check = await localClientWorker.checkException();
              expect(check, isTrue);
            } finally {
              localWorker.stop();
            }
          });

          test('- WorkerPool', () async {
            final identity = LocalServiceImpl();
            final localIdentity = LocalWorker.create(identity);

            try {
              final identityWorkerPool = LocalClientWorkerPool(
                  testContext,
                  localIdentity,
                  ConcurrencySettings(
                      minWorkers: 2, maxWorkers: 4, maxParallel: 3));

              final tasks = <Future<bool>>[];

              for (var i = 0;
                  i <
                      identityWorkerPool.concurrencySettings.maxParallel *
                          identityWorkerPool.concurrencySettings.maxWorkers;
                  i++) {
                tasks.add(identityWorkerPool.checkException());
              }

              final results = await Future.wait(tasks);

              for (var result in results) {
                expect(result, isTrue);
              }
            } finally {
              localIdentity.stop();
            }
          });
        });

        group('- Stream', () {
          test('- LocalWorker', () async {
            final localService = LocalServiceImpl();
            var res1 = await localService.sequence(19).toList();
            expect(res1, equals(Iterable.generate(19)));

            final localWorker = LocalWorker.create(localService);
            try {
              final res2 = await localWorker.channel!.sendStreamingRequest(
                  LocalService.sequenceCommand, [19]).toList();
              expect(res2, equals(Iterable.generate(19)));
            } finally {
              localWorker.stop();
            }
          });

          test('- Squadron Worker', () async {
            final localService = LocalServiceImpl();
            final localWorker = LocalWorker.create(localService);

            try {
              final localClientWorker = LocalClientWorker(testContext,
                  args: [localWorker.channel?.share().serialize()]);
              final res = await localClientWorker.checkSequence(19).toList();
              expect(res.length, equals(19));
              expect(res.every((e) => e['ok']), isTrue);
            } finally {
              localWorker.stop();
            }
          });

          test('- WorkerPool', () async {
            final identity = LocalServiceImpl();
            final localIdentity = LocalWorker.create(identity);

            try {
              final identityWorkerPool = LocalClientWorkerPool(
                  testContext,
                  localIdentity,
                  ConcurrencySettings(
                      minWorkers: 2, maxWorkers: 4, maxParallel: 3));

              final tasks = <Future<List<dynamic>>>[];

              for (var i = 0; i < identityWorkerPool.maxConcurrency; i++) {
                tasks.add(identityWorkerPool.checkSequence(i).toList());
              }

              final results = await Future.wait(tasks);

              for (var i = 0; i < results.length; i++) {
                expect(results[i].every((e) => e['ok']), isTrue);
              }
            } finally {
              localIdentity.stop();
            }
          });
        });
      });
    });
