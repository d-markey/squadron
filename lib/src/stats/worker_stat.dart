import 'package:meta/meta.dart';

/// Base statistics for worker.
class WorkerStat {
  WorkerStat._(
      this.workerType,
      this._id,
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

  /// The worker ID.
  String get id => _id;
  String _id;

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

@internal
extension WorkerStatExt on WorkerStat {
  WorkerStat withWorkerId(String workerId) {
    _id = workerId;
    return this;
  }

  static WorkerStat create(
          Type workerType,
          String id,
          bool isStopped,
          String status,
          int workload,
          int maxWorkload,
          int totalWorkload,
          int totalErrors,
          Duration upTime,
          Duration idleTime) =>
      WorkerStat._(workerType, id, isStopped, status, workload, maxWorkload,
          totalWorkload, totalErrors, upTime, idleTime);
}
