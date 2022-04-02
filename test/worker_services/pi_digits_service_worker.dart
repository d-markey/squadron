import 'dart:async';

import 'package:squadron/squadron.dart';

import 'pi_digits_service.dart';
import 'worker_entry_points.dart';

class PiDigitsWorkerPool extends WorkerPool<PiDigitsWorker>
    implements PiDigitsService {
  PiDigitsWorkerPool([ConcurrencySettings? concurrencySettings])
      : super(() => PiDigitsWorker(),
            concurrencySettings:
                concurrencySettings ?? ConcurrencySettings.threeCpuThreads);

  @override
  Future<int> getNth(int n, [PerfCounter? counter]) =>
      execute((w) => w.getNth(n), counter: counter);

  @override
  Stream<int> getNDigits(int start, int n) =>
      stream((w) => w.getNDigits(start, n));
}

class PiDigitsWorker extends Worker implements PiDigitsService {
  PiDigitsWorker() : super(EntryPoints.piDigits);

  @override
  Future<int> getNth(int n) => send(PiDigitsService.getNthCommand, [n]);

  @override
  Stream<int> getNDigits(int start, int n) =>
      stream(PiDigitsService.getNDigitsCommand, [start, n]);
}
