part of 'worker.dart';

class _Stats {
  _Stats(Worker w)
      : _idle = Timestamp.now(),
        _worker = w;

  final Worker _worker;

  void start() {
    _idle = _started = Timestamp.now();
  }

  void stop() {
    _stopped = Timestamp.now();
  }

  void beginWork() {
    _workload++;
    if (_workload > _maxWorkload) {
      _maxWorkload = _workload;
    }
  }

  void endWork([dynamic _]) {
    _workload--;
    _totalWorkload++;
    if (_workload == 0) {
      _idle = Timestamp.now();
    }
  }

  void failed() {
    _totalErrors++;
  }

  /// Start timestamp
  Timestamp? _started;

  /// Stopped timestamp
  Timestamp? _stopped;

  /// Idle timestamp.
  Timestamp _idle;

  /// Current workload.
  int _workload = 0;

  /// Maximum acceptable workload.
  int _maxWorkload = 0;

  /// Total processed workload.
  int _totalWorkload = 0;

  /// Total errors.
  int _totalErrors = 0;

  Duration _getUpTime(Timestamp timestamp) =>
      (_started == null) ? Duration.zero : timestamp.elapsedSince(_started!);

  Duration _getIdleTime(Timestamp timestamp) =>
      (_workload > 0) ? Duration.zero : timestamp.elapsedSince(_idle);

  /// Indicates if the [Worker] has been stopped.
  bool get isStopped => _stopped != null;

  WorkerStat get snapshot {
    final ts = Timestamp.now();
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
      _worker._channel?.getActiveConnections() ?? 0,
    );
  }
}
