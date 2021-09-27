/// Base statistics for worker
class WorkerStat {
  /// Constructor
  WorkerStat(
      this.workerType,
      this.id,
      this.isStopped,
      this.status,
      this.workload,
      this.maxWorkload,
      this.totalWorkload,
      this.totalErrors,
      this.upTime,
      this.idleTime);

  /// The worker's runtime type
  final Type workerType;

  /// The worker ID
  final String id;

  /// Worker running flag
  final bool isStopped;

  /// Worker status
  final String status;

  /// Current workload being processed by the worker
  final int workload;

  /// Maximum concurrent workload processed by the worker
  final int maxWorkload;

  /// Total workload processed by the worker
  final int totalWorkload;

  /// Total errors raised during processing
  final int totalErrors;

  /// The worker's up-time
  Duration upTime;

  /// The worker's idle-time
  Duration idleTime;

  @override
  String toString() =>
      '$workerType $id: $status, load = $workload (max = $maxWorkload, total = $totalWorkload, errors = $totalErrors), uptime = $upTime, idle = $idleTime';
}
