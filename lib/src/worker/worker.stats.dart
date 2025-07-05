part of 'worker.dart';

class _Stats {
  _Stats(Worker w)
      : _idle = microsecTimeStamp(),
        _worker = w;

  final Worker _worker;

  void start() {
    _idle = _started = microsecTimeStamp();
  }

  void stop() {
    _stopped = microsecTimeStamp();
  }

  void beginWork() {
    _workload++;
    if (_workload > _maxWorkload) {
      _maxWorkload = _workload;
    }
  }

  void endWork([dynamic _]) {
    _workload--;
    _idle = microsecTimeStamp();
    _totalWorkload++;
  }

  void failed() {
    _totalErrors++;
  }

  /// Start timestamp
  int? _started;

  /// Stopped timestamp
  int? _stopped;

  /// Idle timestamp.
  int _idle;

  /// Current workload.
  int _workload = 0;

  /// Maximum acceptable workload.
  int _maxWorkload = 0;

  /// Total processed workload.
  int _totalWorkload = 0;

  /// Total errors.
  int _totalErrors = 0;

  Duration _getUpTime(int microsec) => (_started == null)
      ? Duration.zero
      : Duration(microseconds: microsec - _started!);

  Duration _getIdleTime(int microsec) => (_workload > 0)
      ? Duration.zero
      : Duration(microseconds: microsec - _idle);

  /// Indicates if the [Worker] has been stopped.
  bool get isStopped => _stopped != null;

  WorkerStat get snapshot {
    final ts = microsecTimeStamp();
    return WorkerStatImpl.create(
      _worker.runtimeType,
      _worker.hashCode,
      isStopped,
      _workload,
      _maxWorkload,
      _totalWorkload,
      _totalErrors,
      _getUpTime(_stopped ?? ts),
      _getIdleTime(ts),
      _worker._channel?.activeConnections ?? 0,
    );
  }
}
