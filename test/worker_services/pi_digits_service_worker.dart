import 'dart:async';

import 'package:squadron/squadron.dart';

import 'pi_digits_service.dart';

class PiDigitsWorkerPool extends WorkerPool<PiDigitsWorker>
    implements PiDigitsService {
  PiDigitsWorkerPool(
      dynamic entryPoint, ConcurrencySettings? concurrencySettings)
      : super(() => PiDigitsWorker(entryPoint),
            concurrencySettings:
                concurrencySettings ?? ConcurrencySettings.fourCpuThreads);

  @override
  Future<int> getNth(int n) => execute((w) => w.getNth(n));

  @override
  Stream<int> getNDigits(int start, int n) =>
      stream((w) => w.getNDigits(start, n));
}

class PiDigitsWorker extends Worker implements PiDigitsService {
  PiDigitsWorker(dynamic entryPoint) : super(entryPoint);

  @override
  Future<int> getNth(int n) => send(PiDigitsService.getNthCommand, [n]);

  @override
  Stream<int> getNDigits(int start, int n) =>
      stream(PiDigitsService.getNDigitsCommand, [start, n]);
}
