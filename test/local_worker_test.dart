@TestOn('vm || browser')
library;

import 'package:squadron/squadron.dart';
import 'package:test/test.dart';
import 'package:using/using.dart';

import 'classes/platform.dart';
import 'classes/test_context.dart';
import 'classes/utils.dart';
import 'worker_services/local_client_worker.dart';
import 'worker_services/local_workers/local_service.dart';

void main() async {
  final testContext = await TestContext.init('');
  execute(testContext);
}

String testScript = 'local_worker_test.dart';

void execute(TestContext tc) {
  tc.run(() {
    final localService = LocalServiceImpl();
    final regExp = RegExp(
        'Worker running as "(0x[0-9A-Fa-f]+)", LocalService running as "(0x[0-9A-Fa-f]+)"');

    tc.group("- LocalWorker", () {
      tc.group('- Identity', () {
        tc.test('- LocalWorker', () async {
          var id = localService.getId();
          expect(id, equals('LocalService running as "$threadId"'));

          await LocalWorker.create(
            localService,
          ).useAsync((localWorker) async {
            final id = await localWorker.channel
                ?.sendRequest(LocalService.getIdCommand, []);
            expect(id, equals('LocalService running as "$threadId"'));
          });
        });

        tc.test('- Squadron Worker', () async {
          await LocalWorker.create(
            localService,
          ).useAsync((localWorker) async {
            await LocalClientWorker(
              tc,
              args: [localWorker.channel?.share().serialize()],
            ).useAsync((localClientWorker) async {
              final check = await localClientWorker.checkIds();

              final match = regExp.firstMatch(check);
              expect(match, isNotNull);
              expect(match!.group(1), isNot(equals(match.group(2))));
            });
          });
        });

        tc.test('- WorkerPool', () async {
          await LocalWorker.create(
            localService,
          ).useAsync((localWorker) async {
            await LocalClientWorkerPool(
              tc,
              localWorker,
              ConcurrencySettings(minWorkers: 2, maxWorkers: 4, maxParallel: 3),
            ).useAsync((workerPool) async {
              final tasks = <Future<String>>[];

              for (var i = 0; i < workerPool.maxConcurrency; i++) {
                tasks.add(workerPool.checkIds());
              }

              final results = await Future.wait(tasks);

              final workerIds = <String>{};
              for (var result in results) {
                expect(result, matches(regExp));
                final match = regExp.firstMatch(result)!;
                final wid = match.group(1);
                expect(wid, isNotNull);
                expect(wid, isNot(equals(threadId)));
                expect(match.group(2), equals(threadId));
                workerIds.add(wid!);
              }
            });
          });
        });
      });

      tc.group('- Exception', () {
        tc.test('- LocalWorker', () async {
          try {
            final res = localService.throwException();
            throw unexpectedSuccess('throwException()', res);
          } catch (ex) {
            lowerCaseCheck(ex, contains('intentional exception'));
          }

          await LocalWorker.create(
            localService,
          ).useAsync((localWorker) async {
            try {
              final res = await localWorker.channel
                  ?.sendRequest(LocalService.throwExceptionCommand, []);
              throw unexpectedSuccess('throwException()', res);
            } on WorkerException catch (ex) {
              lowerCaseCheck(ex.message, contains('intentional exception'));
              caseCheck(ex.stackTrace, contains('throwException'));
            }
          });
        });

        tc.test('- Squadron Worker', () async {
          final localWorker = LocalWorker.create(localService);

          await LocalClientWorker(
            tc,
            args: [localWorker.channel?.share().serialize()],
          ).useAsync((localClientWorker) async {
            final check = await localClientWorker.checkException();
            expect(check, isTrue);
          });
        });

        tc.test('- WorkerPool', () async {
          await LocalWorker.create(
            localService,
          ).useAsync((localWorker) async {
            await LocalClientWorkerPool(
              tc,
              localWorker,
              ConcurrencySettings(minWorkers: 2, maxWorkers: 4, maxParallel: 3),
            ).useAsync((pool) async {
              final tasks = <Future<bool>>[];

              for (var i = 0; i < pool.maxConcurrency; i++) {
                tasks.add(pool.checkException());
              }

              final results = await Future.wait(tasks);

              for (var result in results) {
                expect(result, isTrue);
              }
            });
          });
        });
      });

      tc.group('- Stream', () {
        tc.test('- LocalWorker', () async {
          var res1 = await localService.sequence(19).toList();
          expect(res1, equals(Iterable.generate(19)));

          await LocalWorker.create(
            localService,
          ).useAsync((localWorker) async {
            final res2 = await localWorker.channel!.sendStreamingRequest(
                LocalService.sequenceCommand, [19]).toList();
            expect(res2, equals(Iterable.generate(19)));
          });
        });

        tc.test('- Squadron Worker', () async {
          await LocalWorker.create(
            localService,
          ).useAsync((localWorker) async {
            await LocalClientWorker(
              tc,
              args: [localWorker.channel?.share().serialize()],
            ).useAsync((localClientWorker) async {
              final res = await localClientWorker.checkSequence(19).toList();
              expect(res.length, equals(19));
              expect(res.every((e) => e['ok']), isTrue);
            });
          });
        });

        tc.test('- WorkerPool', () async {
          await LocalWorker.create(
            localService,
          ).useAsync((localWorker) async {
            await LocalClientWorkerPool(
              tc,
              localWorker,
              ConcurrencySettings(minWorkers: 2, maxWorkers: 4, maxParallel: 3),
            ).useAsync((pool) async {
              final tasks = <Future<List<dynamic>>>[];
              for (var i = 0; i < pool.maxConcurrency; i++) {
                tasks.add(pool.checkSequence(i).toList());
              }

              final results = await Future.wait(tasks);

              for (var i = 0; i < results.length; i++) {
                expect(results[i].every((e) => e['ok']), isTrue);
              }
            });
          });
        });
      });
    });
  });
}
