import 'dart:async';

import 'package:squadron/squadron.dart';

import 'local_workers/local_client.dart';
import 'local_workers/local_service.dart';
import 'worker_entry_points.dart';

abstract class LocalClientService {
  FutureOr<String> checkIds();
  FutureOr<bool> checkException();
  Stream<dynamic> checkSequence(int count);

  static const checkIdsCommand = 1;
  static const checkExceptionCommand = 2;
  static const checkSequenceCommand = 3;
}

class LocalClientServiceImpl implements LocalClientService, WorkerService {
  LocalClientServiceImpl(this._localClient);

  final LocalClient _localClient;

  @override
  Future<String> checkIds() async =>
      'Worker running as "${Squadron.id}", ${await _localClient.getId()}';

  @override
  Future<bool> checkException() async {
    try {
      await _localClient.throwException();
      throw Exception('throwException() completed successfully');
    } catch (ex) {
      return ex is WorkerException &&
          ex.message.contains('Intentional exception');
    }
  }

  @override
  Stream<dynamic> checkSequence(int count) async* {
    var cur = 0;
    await for (var i in _localClient.sequence(count)) {
      yield {'i': i, 'cur': cur, 'ok': (i == cur)};
      cur++;
    }
  }

  @override
  late final Map<int, CommandHandler> operations = {
    LocalClientService.checkIdsCommand: (req) => checkIds(),
    LocalClientService.checkExceptionCommand: (req) => checkException(),
    LocalClientService.checkSequenceCommand: (req) =>
        checkSequence(req.args[0]),
  };
}

class LocalClientWorkerPool extends WorkerPool<LocalClientWorker>
    implements LocalClientService {
  LocalClientWorkerPool(LocalWorker<LocalService> localService,
      ConcurrencySettings? concurrencySettings)
      : super(
            () => LocalClientWorker(
                args: [localService.channel?.share().serialize()]),
            concurrencySettings:
                concurrencySettings ?? ConcurrencySettings.threeCpuThreads);

  @override
  Future<String> checkIds() => execute((w) => w.checkIds());

  @override
  Future<bool> checkException() => execute((w) => w.checkException());

  @override
  Stream<dynamic> checkSequence(int count) =>
      stream((w) => w.checkSequence(count));
}

class LocalClientWorker extends Worker implements LocalClientService {
  LocalClientWorker({List args = const []})
      : super(EntryPoints.local, args: args);

  @override
  Future<String> checkIds() => send(LocalClientService.checkIdsCommand);

  @override
  Future<bool> checkException() =>
      send(LocalClientService.checkExceptionCommand);

  @override
  Stream<dynamic> checkSequence(int count) =>
      stream(LocalClientService.checkSequenceCommand, args: [count]);
}
