part of 'worker.dart';

class _Stats {
  _Stats(Worker w)
      : _workerType = w.runtimeType,
        _workerHashCode = w.hashCode;

  void start() {
    _started = microsecTimeStamp();
    _idle = _started;
  }

  void stop() {
    _stopped = microsecTimeStamp();
  }

  void beginWork() {
    _workload++;
    _idle = null;
    if (_workload > _maxWorkload) {
      _maxWorkload = _workload;
    }
  }

  void endWork([dynamic _]) {
    _workload--;
    if (_workload == 0) {
      _idle = microsecTimeStamp();
    }
    _totalWorkload++;
  }

  void failed() {
    _totalErrors++;
  }

  /// Start timestamp (in microseconds since Epoch).
  int? _started;

  /// Stopped timestamp (in microseconds since Epoch).
  int? _stopped;

  /// Current workload.
  int _workload = 0;

  /// Maximum acceptable workload.
  int _maxWorkload = 0;

  /// Total processed workload.
  int _totalWorkload = 0;

  /// Total errors.
  int _totalErrors = 0;

  /// Up time.
  Duration get upTime => (_started == null)
      ? Duration.zero
      : Duration(microseconds: (_stopped ?? microsecTimeStamp()) - _started!);

  /// Idle time.
  Duration get idleTime => (_workload > 0 || _idle == null)
      ? Duration.zero
      : Duration(microseconds: microsecTimeStamp() - _idle!);
  int? _idle;

  /// Indicates if the [Worker] has been stopped.
  bool get isStopped => _stopped != null;

  /// [Worker] status.
  String get status {
    if (isStopped) {
      return 'STOPPED';
    } else if (_workload == 0) {
      return 'IDLE';
    } else {
      return 'WORKING($_workload)';
    }
  }

  final Type _workerType;
  final int _workerHashCode;

  WorkerStat get snapshot => WorkerStatImpl.create(
        _workerType,
        _workerHashCode,
        isStopped,
        status,
        _workload,
        _maxWorkload,
        _totalWorkload,
        _totalErrors,
        upTime,
        idleTime,
      );
}
