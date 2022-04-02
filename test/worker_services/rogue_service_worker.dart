import 'dart:async';

import 'package:squadron/squadron.dart';

import 'rogue_service.dart';
import 'worker_entry_points.dart';

class RogueWorkerPool extends WorkerPool<RogueWorker> implements RogueService {
  RogueWorkerPool(ConcurrencySettings? concurrencySettings)
      : super(() => RogueWorker(),
            concurrencySettings:
                concurrencySettings ?? ConcurrencySettings.threeCpuThreads);

  @override
  Future throwWorkerException() => execute((w) => w.throwWorkerException());

  @override
  Future throwException() => execute((w) => w.throwException());

  @override
  Future throwCustomException() => execute((w) => w.throwCustomException());

  @override
  Future<dynamic> forward(dynamic data) => execute((w) => w.forward(data));

  @override
  Future missingOperation() => execute((w) => w.missingOperation());

  @override
  Future<dynamic> invalidResponse() => execute((w) => w.invalidResponse());

  @override
  Future<bool> ping() => execute((w) => w.ping());
}

class RogueWorker extends Worker implements RogueService {
  RogueWorker() : super(EntryPoints.rogue);

  @override
  Future throwWorkerException() => send(RogueService.workerExceptionCommand);

  @override
  Future throwException() => send(RogueService.exceptionCommand);

  @override
  Future throwCustomException() => send(RogueService.customExceptionCommand);

  @override
  Future<dynamic> forward(dynamic data) =>
      send(RogueService.forwardCommand, [data]);

  @override
  Future missingOperation() => send(RogueService.missingCommand);

  @override
  Future<dynamic> invalidResponse() =>
      send(RogueService.invalidResponseCommand);

  @override
  Future<bool> ping() => send(RogueService.pingCommand);
}
