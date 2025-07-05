import 'package:meta/meta.dart';

/// Base statistics for worker.
class WorkerStat {
  WorkerStat._(
    this.workerType,
    this.workerHashCode,
    this.isStopped,
    this.workload,
    this.maxWorkload,
    this.totalWorkload,
    this.totalErrors,
    this.upTime,
    this.idleTime,
    this.activeConnections,
  );

  /// Timestamp of this snapshot
  final timestamp = DateTime.now().toUtc();

  /// The worker's runtime type.
  final Type workerType;

  /// The worker's hashCode.
  final int workerHashCode;

  /// Worker running flag.
  final bool isStopped;

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

  /// The worker channel's count of active connections.
  final int activeConnections;
}

extension WorkerStatsExt on Iterable<WorkerStat> {
  /// Gets the total workload from a collection of worker stats.
  int get workload => fold<int>(0, (p, s) => p + s.workload);

  /// Gets the grand total of workloads from a collection of worker stats.
  int get totalWorkload => fold<int>(0, (p, s) => p + s.totalWorkload);

  /// Gets the grand total of errors from a collection of worker stats.
  int get totalErrors => fold<int>(0, (p, s) => p + s.totalErrors);
}

@internal
extension WorkerStatImpl on WorkerStat {
  static WorkerStat create(
          Type workerType,
          int workerHashCode,
          bool isStopped,
          int workload,
          int maxWorkload,
          int totalWorkload,
          int totalErrors,
          Duration upTime,
          Duration idleTime,
          int activeConnections) =>
      WorkerStat._(workerType, workerHashCode, isStopped, workload, maxWorkload,
          totalWorkload, totalErrors, upTime, idleTime, activeConnections);
}
