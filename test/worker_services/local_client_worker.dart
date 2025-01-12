import 'dart:async';

import 'package:squadron/squadron.dart';
import 'package:using/using.dart';

import '../src/test_context.dart';
import '../src/utils.dart';
import 'local_workers/local_client.dart';
import 'local_workers/local_service.dart';
import 'squadron_version.dart';

abstract class LocalClientService with SquadronVersion {
  FutureOr<String> checkIds();
  FutureOr<bool> checkException();
  Stream<Map<String, dynamic>> checkSequence(int count);

  static const checkIdsCommand = 1;
  static const checkExceptionCommand = 2;
  static const checkSequenceCommand = 3;
}

class LocalClientServiceImpl
    with Releasable, SquadronVersion
    implements LocalClientService, WorkerService {
  LocalClientServiceImpl(this._localClient) {
    operations.addAll({
      SquadronVersion.versionCommand: (r) => getVersion(),
      LocalClientService.checkIdsCommand: (req) => checkIds(),
      LocalClientService.checkExceptionCommand: (req) => checkException(),
      LocalClientService.checkSequenceCommand: (req) =>
          checkSequence(Squadron.converter.value<int>()(req.args[0])),
    });
  }

  @override
  void release() {
    _localClient.release();
    super.release();
  }

  final LocalClient _localClient;

  @override
  Future<String> checkIds() async =>
      'Worker running as "$threadId", ${await _localClient.getId()}';

  @override
  Future<bool> checkException() async {
    try {
      final res = await _localClient.throwException();
      throw unexpectedSuccess('throwException()', res);
    } on WorkerException catch (ex) {
      return ex.message.toLowerCase().contains('intentional exception');
    }
  }

  @override
  Stream<Map<String, dynamic>> checkSequence(int count) async* {
    var cur = 0;
    await for (var i in _localClient.sequence(count)) {
      yield {'i': i, 'cur': cur, 'ok': (i == cur)};
      cur++;
    }
  }

  @override
  final Map<int, CommandHandler> operations = {};
}

base class LocalClientWorkerPool extends WorkerPool<LocalClientWorker>
    with PoolVersion<LocalClientWorker>
    implements LocalClientService {
  LocalClientWorkerPool(
    TestContext context,
    LocalWorker<LocalService> localService,
    ConcurrencySettings? concurrencySettings, {
    ExceptionManager? exceptionManager,
  }) : super(
            (ExceptionManager exceptionManager) =>
                LocalClientWorker(context, localService),
            concurrencySettings:
                concurrencySettings ?? ConcurrencySettings.threeCpuThreads,
            exceptionManager:
                exceptionManager ?? localService.exceptionManager);

  @override
  Future<String> checkIds() => execute((w) => w.checkIds());

  @override
  Future<bool> checkException() => execute((w) => w.checkException());

  @override
  Stream<Map<String, dynamic>> checkSequence(int count) =>
      stream((w) => w.checkSequence(count));
}

base class LocalClientWorker extends Worker
    with WorkerVersion
    implements LocalClientService {
  LocalClientWorker(TestContext context, LocalWorker<LocalService> localService,
      {ExceptionManager? exceptionManager})
      : super(
          context.entryPoints.local!,
          args: [localService.channel?.share().serialize()],
          exceptionManager: exceptionManager ?? localService.exceptionManager,
        );

  @override
  Future<String> checkIds() => send(LocalClientService.checkIdsCommand)
      .then(Squadron.converter.value<String>());

  @override
  Future<bool> checkException() =>
      send(LocalClientService.checkExceptionCommand)
          .then(Squadron.converter.value<bool>());

  @override
  Stream<Map<String, dynamic>> checkSequence(int count) =>
      stream(LocalClientService.checkSequenceCommand, args: [count])
          .map(Squadron.converter.map<String, dynamic>());
}
