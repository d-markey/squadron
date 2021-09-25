class WorkerStat {
  WorkerStat(this.workerType, this.id, this.status, this.workload, this.maxWorkload, this.totalWorkload, this.totalErrors, this.upTime, this.idleTime);

  final Type workerType;
  final String id;
  final String status;
  final int workload;
  final int maxWorkload;
  final int totalWorkload;
  final int totalErrors;
  Duration? upTime;
  Duration? idleTime;

  @override
  String toString() =>
      '$workerType $id: $status, load = $workload (max = $maxWorkload, total = $totalWorkload, errors = $totalErrors), uptime = $upTime, idle = $idleTime';
}
