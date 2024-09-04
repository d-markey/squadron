import 'dart:async';

import 'package:squadron/squadron.dart';

import '../classes/test_context.dart';
import '../classes/utils.dart';
import 'local_workers/local_client.dart';
import 'local_workers/local_service.dart';

abstract class LocalClientService {
  FutureOr<String> checkIds();
  FutureOr<bool> checkException();
  Stream<Map<String, dynamic>> checkSequence(int count);

  static const checkIdsCommand = 1;
  static const checkExceptionCommand = 2;
  static const checkSequenceCommand = 3;
}

class LocalClientServiceImpl implements LocalClientService, WorkerService {
  LocalClientServiceImpl(this._localClient);

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
  late final Map<int, CommandHandler> operations = {
    LocalClientService.checkIdsCommand: (req) => checkIds(),
    LocalClientService.checkExceptionCommand: (req) => checkException(),
    LocalClientService.checkSequenceCommand: (req) =>
        checkSequence(platformConverter.v<int>()(req.args[0])),
  };
}

class LocalClientWorkerPool extends WorkerPool<LocalClientWorker>
    implements LocalClientService {
  LocalClientWorkerPool(
      TestContext context,
      LocalWorker<LocalService> localService,
      ConcurrencySettings? concurrencySettings)
      : super(
            () => LocalClientWorker(context, args: [
                  context.useNumConverter,
                  localService.channel?.share().serialize(),
                ]),
            concurrencySettings:
                concurrencySettings ?? ConcurrencySettings.threeCpuThreads);

  @override
  Future<String> checkIds() => execute((w) => w.checkIds());

  @override
  Future<bool> checkException() => execute((w) => w.checkException());

  @override
  Stream<Map<String, dynamic>> checkSequence(int count) =>
      stream((w) => w.checkSequence(count));
}

class LocalClientWorker extends Worker implements LocalClientService {
  LocalClientWorker(TestContext context, {List args = const []})
      : super(context.entryPoints.local!, args: args);

  @override
  Future<String> checkIds() => send(LocalClientService.checkIdsCommand)
      .then(platformConverter.v<String>());

  @override
  Future<bool> checkException() =>
      send(LocalClientService.checkExceptionCommand)
          .then(platformConverter.v<bool>());

  @override
  Stream<Map<String, dynamic>> checkSequence(int count) =>
      stream(LocalClientService.checkSequenceCommand, args: [count])
          .map(platformConverter.m<String, dynamic>());
}
