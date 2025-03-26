import 'package:squadron/squadron.dart';

extension ConcurrencyExt on WorkerPool {
  int get minWorkers => concurrencySettings.minWorkers;
  int get maxWorkers => concurrencySettings.maxWorkers;
  int get maxParallel => concurrencySettings.maxParallel;
  int get maxConcurrency => concurrencySettings.maxConcurrency;
}
