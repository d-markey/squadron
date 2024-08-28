// ignore_for_file: file_names

@TestOn('vm || browser')
library;

import 'dart:async';

import 'package:squadron/squadron.dart';
import 'package:test/test.dart';
import 'package:using/using.dart';

import 'classes/test_context.dart';
import 'classes/utils.dart';
import 'const_concurrency_settings.dart';
import 'worker_services/local_client_worker.dart';
import 'worker_services/local_workers/local_service.dart';

void main() {
  TestContext.init('').then(execute);
  // TestContext.init('', TestPlatform.wasm).then(execute);
}

String testScript = '05_local_worker_test.dart';

void execute(TestContext? tc) {
  if (tc == null) return;

  tc.run(() {
    final localService = LocalServiceImpl();
    final regExp = RegExp(
        'Worker running as "(0x[0-9A-Fa-f]+)", LocalService running as "(0x[0-9A-Fa-f]+)"');

    tc.group("- Local Worker", () {
      tc.group('- Identity', () {
        tc.test('- Local', () async {
          var id = localService.getId();
          expect(id, 'LocalService running as "$threadId"');
          await LocalWorker.create(localService).useAsync((lw) async {
            expect(
              await lw.channel!.sendRequest(LocalService.getIdCommand, []),
              'LocalService running as "$threadId"',
            );
          });
        });

        tc.test('- Squadron', () async {
          await LocalWorker.create(localService).useAsync((lw) async {
            final shared = lw.channel!.share();
            await LocalClientWorker(tc, args: [shared.serialize()])
                .useAsync((w) async {
              final check = await w.checkIds();
              final match = regExp.firstMatch(check)!;
              expect(match.group(1), isNot(match.group(2)));
            });
          });
        });

        tc.test('- Pool', () async {
          await LocalWorker.create(localService).useAsync((lw) async {
            await LocalClientWorkerPool(tc, lw, concurrency_253)
                .useAsync((p) async {
              final tasks = <Future<String>>[];
              for (var i = 0; i < p.maxConcurrency; i++) {
                tasks.add(p.checkIds());
              }

              final results = await Future.wait(tasks);
              for (var result in results) {
                final match = regExp.firstMatch(result)!;
                final wid = match.group(1);
                expect(wid, isNotNull);
                expect(wid, isNot(threadId));
                expect(match.group(2), threadId);
              }
            });
          });
        });
      });

      tc.group('- Exception', () {
        tc.test('- Local', () async {
          try {
            final res = localService.throwException();
            throw unexpectedSuccess('throwException()', res);
          } catch (ex) {
            expect(ex, reports('Intentional exception'));
          }

          await LocalWorker.create(localService).useAsync((lw) async {
            try {
              final res = await lw.channel!
                  .sendRequest(LocalService.throwExceptionCommand, []);
              throw unexpectedSuccess('throwException()', res);
            } on WorkerException catch (ex) {
              expect(ex, reports('Intentional exception'));
              expect(ex.stackTrace, hasCalled('throwException'));
            }
          });
        });

        tc.test('- Squadron', () async {
          await LocalWorker.create(localService).useAsync((lw) async {
            final shared = lw.channel!.share();
            await LocalClientWorker(tc, args: [shared.serialize()])
                .useAsync((w) async {
              expect(await w.checkException(), isTrue);
            });
          });
        });

        tc.test('- Pool', () async {
          await LocalWorker.create(localService).useAsync((lw) async {
            await LocalClientWorkerPool(tc, lw, concurrency_253)
                .useAsync((p) async {
              final tasks = <Future<bool>>[];
              for (var i = 0; i < p.maxConcurrency; i++) {
                tasks.add(p.checkException());
              }

              expect(await Future.wait(tasks), everyElement(isTrue));
            });
          });
        });
      });

      tc.group('- Stream', () {
        tc.test('- Local', () async {
          final list = await localService.sequence(19).toList();
          expect(list, Iterable.generate(19));

          await LocalWorker.create(localService).useAsync((lw) async {
            expect(
              await lw.channel!.sendStreamingRequest(
                  LocalService.sequenceCommand, [19]).toList(),
              list,
            );
          });
        });

        tc.test('- Squadron', () async {
          await LocalWorker.create(localService).useAsync((lw) async {
            final shared = lw.channel?.share();
            await LocalClientWorker(tc, args: [shared?.serialize()])
                .useAsync((w) async {
              final res = await w.checkSequence(19).toList();
              expect(res, hasLength(19));
              expect(res.map((e) => e['ok']), everyElement(isTrue));
            });
          });
        });

        tc.test('- Pool', () async {
          await LocalWorker.create(localService).useAsync((lw) async {
            await LocalClientWorkerPool(tc, lw, concurrency_253)
                .useAsync((p) async {
              final tasks = <Future<List<dynamic>>>[];
              for (var i = 0; i < p.maxConcurrency; i++) {
                tasks.add(p.checkSequence(i).toList());
              }

              final results = await Future.wait(tasks);
              for (var i = 0; i < results.length; i++) {
                expect(results[i], hasLength(i));
                expect(results[i].map((e) => e['ok']), everyElement(isTrue));
              }
            });
          });
        });
      });
    });
  });
}
