import 'package:squadron/squadron.dart';
import 'package:test/test.dart';

import '../worker_services/local_client_worker.dart';
import '../worker_services/local_workers/local_service.dart';

String idGetter() => 'LocalWorker running as "${Squadron.id}"';

void localWorkerTests() {
  setUp(() {
    // Squadron.logger = ConsoleSquadronLogger();
  });

  group('- Identity', () {
    test('- LocalWorker', () async {
      final localService = LocalServiceImpl(idGetter);
      var id = localService.getId();
      expect(id, equals(idGetter()));

      final localWorker = LocalWorker.create(localService);
      try {
        final id = await localWorker.channel
            ?.sendRequest(LocalService.getIdCommand, []);
        expect(id, equals(idGetter()));
      } finally {
        localWorker.stop();
      }
    });

    test('- Worker', () async {
      final localService = LocalServiceImpl(idGetter);
      final localWorker = LocalWorker.create(localService);

      try {
        final localClientWorker =
            LocalClientWorker(args: [localWorker.channel?.share().serialize()]);
        final check = await localClientWorker.checkIds();

        final localWorkerId = idGetter().replaceAll('.', '\\.');
        final squadronId = Squadron.id?.replaceAll('.', '\\.');
        final regExp =
            RegExp('Worker running as "$squadronId\\.\\d+", $localWorkerId');
        expect(check, matches(regExp));
      } finally {
        localWorker.stop();
      }
    });

    test('- WorkerPool', () async {
      final localService = LocalServiceImpl(idGetter);
      final localWorker = LocalWorker.create(localService);

      try {
        final localClientWorkerPool = LocalClientWorkerPool(localWorker,
            ConcurrencySettings(minWorkers: 2, maxWorkers: 4, maxParallel: 3));

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
        final localWorkerId = idGetter().replaceAll('.', '\\.');
        final squadronId = Squadron.id?.replaceAll('.', '\\.');
        final regExp =
            RegExp('Worker running as "($squadronId\\.\\d+)", $localWorkerId');
        for (var result in results) {
          expect(result, matches(regExp));
          final match = regExp.firstMatch(result)!;
          final id = match.group(1);
          expect(id, isNotNull);
          workerIds.add(id!);
        }
        expect(workerIds.length,
            equals(localClientWorkerPool.concurrencySettings.maxWorkers));
      } finally {
        localWorker.stop();
      }
    });
  });

  group('- Exception', () {
    test('- LocalWorker', () async {
      final localService = LocalServiceImpl(idGetter);
      try {
        localService.throwException();
        // should never happen
        throw Exception('throwException() completed successfully');
      } catch (ex) {
        expect(ex.toString(), contains('Intentional exception'));
      }

      final localWorker = LocalWorker.create(localService);
      try {
        await localWorker.channel
            ?.sendRequest(LocalService.throwExceptionCommand, []);
        // should never happen
        throw Exception('throwException() completed successfully');
      } catch (ex) {
        expect(ex, isA<WorkerException>());
        final wex = ex as WorkerException;
        expect(wex.message, contains('Intentional exception'));
        expect(wex.stackTrace.toString(), contains('throwException'));
      }
    });

    test('- Worker', () async {
      final localService = LocalServiceImpl(idGetter);
      final localWorker = LocalWorker.create(localService);

      try {
        final localClientWorker =
            LocalClientWorker(args: [localWorker.channel?.share().serialize()]);
        final check = await localClientWorker.checkException();
        expect(check, isTrue);
      } finally {
        localWorker.stop();
      }
    });

    test('- WorkerPool', () async {
      String idGetter() => 'LocalWorker running as "${Squadron.id}"';

      final identity = LocalServiceImpl(idGetter);
      final localIdentity = LocalWorker.create(identity);

      try {
        final identityWorkerPool = LocalClientWorkerPool(localIdentity,
            ConcurrencySettings(minWorkers: 2, maxWorkers: 4, maxParallel: 3));

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
      final localService = LocalServiceImpl(idGetter);
      var res1 = await localService.sequence(19).toList();
      expect(res1, equals(Iterable.generate(19)));

      final localWorker = LocalWorker.create(localService);
      try {
        final res2 = await localWorker.channel!
            .sendStreamingRequest(LocalService.sequenceCommand, [19]).toList();
        expect(res2, equals(Iterable.generate(19)));
      } finally {
        localWorker.stop();
      }
    });

    test('- Worker', () async {
      final localService = LocalServiceImpl(idGetter);
      final localWorker = LocalWorker.create(localService);

      try {
        final localClientWorker =
            LocalClientWorker(args: [localWorker.channel?.share().serialize()]);
        final res = await localClientWorker.checkSequence(19).toList();
        expect(res.map((e) => e['ok']),
            equals(Iterable.generate(19, (_) => true)));
      } finally {
        localWorker.stop();
      }
    });

    test('- WorkerPool', () async {
      String idGetter() => 'LocalWorker running as "${Squadron.id}"';

      final identity = LocalServiceImpl(idGetter);
      final localIdentity = LocalWorker.create(identity);

      try {
        final identityWorkerPool = LocalClientWorkerPool(localIdentity,
            ConcurrencySettings(minWorkers: 2, maxWorkers: 4, maxParallel: 3));

        final tasks = <Future<List<dynamic>>>[];

        for (var i = 0; i < identityWorkerPool.maxConcurrency; i++) {
          tasks.add(identityWorkerPool.checkSequence(i).toList());
        }

        final results = await Future.wait(tasks);

        for (var i = 0; i < results.length; i++) {
          expect(results[i].map((e) => e['ok']),
              equals(Iterable.generate(i, (_) => true)));
        }
      } finally {
        localIdentity.stop();
      }
    });
  });
}
