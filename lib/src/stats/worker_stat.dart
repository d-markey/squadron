import 'package:meta/meta.dart';

/// Base statistics for worker.
class WorkerStat {
  WorkerStat._(
      this.workerType,
      this.workerHashCode,
      this.isStopped,
      this.status,
      this.workload,
      this.maxWorkload,
      this.totalWorkload,
      this.totalErrors,
      this.upTime,
      this.idleTime);

  /// The worker's runtime type.
  final Type workerType;

  /// The worker's hashCode.
  final int workerHashCode;

  /// Worker running flag.
  final bool isStopped;

  /// Worker status.
  final String status;

  /// Current workload being processed by the worker.
  final int workload;

  /// Maximum concurrent workload processed by the worker.
  final int maxWorkload;

  /// Total workload processed by the worker.
  final int totalWorkload;

  /// Total errors raised during processing.
  final int totalErrors;

  /// The worker's up-time.
  Duration upTime;

  /// The worker's idle-time.
  Duration idleTime;
}

extension WorkerStatsExt on Iterable<WorkerStat> {
  int get workload => fold<int>(0, (p, s) => p + s.workload);
  int get totalWorkload => fold<int>(0, (p, s) => p + s.totalWorkload);
  int get totalErrors => fold<int>(0, (p, s) => p + s.totalErrors);
}

@internal
extension WorkerStatImpl on WorkerStat {
  static WorkerStat create(
          Type workerType,
          int workerHashCode,
          bool isStopped,
          String status,
          int workload,
          int maxWorkload,
          int totalWorkload,
          int totalErrors,
          Duration upTime,
          Duration idleTime) =>
      WorkerStat._(workerType, workerHashCode, isStopped, status, workload,
          maxWorkload, totalWorkload, totalErrors, upTime, idleTime);
}
