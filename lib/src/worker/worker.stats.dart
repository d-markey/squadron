part of 'worker.dart';

class _Stats {
  _Stats(Worker w) : _worker = w {
    _idleTime.start();
  }

  final Worker _worker;
  final _idleTime = Stopwatch();
  Stopwatch? _upTime;
  Duration? _initTime;

  void start() {
    if (_upTime == null) {
      _initTime = _idleTime.elapsed;
      _upTime = Stopwatch()..start();
      _idleTime.reset();
      _idleTime.start();
    }
  }

  void stop() {
    _initTime ??= Duration.zero;
    (_upTime ??= Stopwatch()).stop();
  }

  void beginWork() {
    _idleTime.stop();
    _idleTime.reset();
    _workload++;
    if (_workload > _maxWorkload) {
      _maxWorkload = _workload;
    }
  }

  void endWork([dynamic _]) {
    _workload--;
    _totalWorkload++;
    if (_workload == 0) {
      _idleTime.reset();
      _idleTime.start();
    }
  }

  void failed() {
    _totalErrors++;
  }

  /// Current workload.
  int _workload = 0;

  /// Maximum acceptable workload.
  int _maxWorkload = 0;

  /// Total processed workload.
  int _totalWorkload = 0;

  /// Total errors.
  int _totalErrors = 0;

  /// Indicates if the [Worker] has been stopped.
  bool get isStopped => _upTime?.isRunning == false;

  WorkerStat get snapshot {
    // measure idle time before up time
    final idleTime = _idleTime.elapsed;
    return WorkerStatImpl.create(
      _worker.runtimeType,
      _worker.hashCode,
      isStopped,
      _workload,
      _maxWorkload,
      _totalWorkload,
      _totalErrors,
      _initTime,
      _upTime?.elapsed ?? Duration.zero,
      idleTime,
      _worker._channel?.getActiveConnections() ?? 0,
    );
  }
}
