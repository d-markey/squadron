import 'dart:async';
import 'dart:isolate';

import 'package:squadron/squadron.dart';

import 'worker_request.dart';
import 'worker_stat.dart';

/// Base worker class.
///
/// This base class takes care of creating the [Isolate] to execute the worker's main program.
/// It also implements communication with the [Isolate].
///
/// Typically, derived classes should add proxy methods for the worker's main program services
/// and use the [send] method to forward commands to the worker's main program.
abstract class Worker {

  /// Creates a worker with the specified main program
  Worker(this._main, {String? id}) {
    this.id = id ?? hashCode.toString();
  }

  /// The thread's entry point 
  final void Function(List args) _main;

  /// Worker id
  late final String id;

  /// Start timestamp (in microseconds since Epoch)
  DateTime? get started => (_started == null) ? null : DateTime.fromMicrosecondsSinceEpoch(_started!);
  int? _started;

  /// Idle timestamp (in microseconds since Epoch)
  int? _idle;

  /// Stopped timestamp (in microseconds since Epoch)
  DateTime? get stopped => (_stopped == null) ? null : DateTime.fromMicrosecondsSinceEpoch(_stopped!);
  int? _stopped;


  /// Current workload
  int get workload => _workload;
  int _workload = 0;

  /// Maximum workload
  int get maxWorkload => _maxWorkload;
  int _maxWorkload = 0;

  /// Total workload
  int get totalWorkload => _totalWorkload;
  int _totalWorkload = 0;

  /// Number of errors
  int get totalErrors => _totalErrors;
  int _totalErrors = 0;

  /// Up time
  Duration get upTime => (_started == null) ? Duration.zero : Duration(microseconds: (_stopped ?? DateTime.now().microsecondsSinceEpoch) - _started!);

  /// Idle time
  Duration get idleTime => (_workload > 0 || _idle == null) ? Duration.zero : Duration(microseconds: DateTime.now().microsecondsSinceEpoch - _idle!);

  /// Indicates if the worker has been stopped
  bool get isStopped => _stopped != null;

  /// Worker status
  String get status {
    if (isStopped) {
      return 'STOPPED';
    } else if (_workload == 0) {
      return 'IDLE';
    } else {
      return 'WORKING($_workload)';
    }
  }

  /// Statistics
  WorkerStat get stats => WorkerStat(runtimeType, id, status, workload, maxWorkload, totalWorkload, totalErrors, upTime, idleTime);

  /// Command port to communicate with  the worker's [Isolate]
  SendPort? get commandPort => _commandPort;
  SendPort? _commandPort;

  /// Send a workload to the woker's main program running in the worker's [Isolate]
  Future<T> send<T>(int command, [ List args = const [] ]) async {
    try {
      // update stats
      _workload++;
      if (_workload > _maxWorkload) {
        _maxWorkload = _workload;
      }

      // ensure the Isolate is up and running
      _commandPort ??= await start();

      // send request and return response
      return await WorkerRequest(command, args).send<T>(_commandPort!);
    } on WorkerException catch (e) {
      _totalErrors++;
      throw WorkerException(e.message, stackTrace: e.stackTrace, workerId: id);
    } catch (e, st) {
      _totalErrors++;
      throw WorkerException(e.toString(), stackTrace: st.toString(), workerId: id);
    } finally {
      // update stats
      _workload--;
      _totalWorkload++;
      _idle = DateTime.now().microsecondsSinceEpoch;
    }
  }

  /// Send a streaming workload to the woker's main program running in the worker's [Isolate]
  Stream<T> stream<T>(int command, [ List args = const [] ]) async* {
    try {
      // update stats
      _workload++;
      if (_workload > _maxWorkload) {
        _maxWorkload = _workload;
      }

      // ensure the Isolate is up and running
      _commandPort ??= await start();

      // send request and stream response elements
      await for (var res in WorkerRequest(command, args).stream<T>(_commandPort!)) {
        yield res;
      }
    } on WorkerException {
      _totalErrors++;
      rethrow;
    } catch (e, st) {
      _totalErrors++;
      throw WorkerException(e.toString(), stackTrace: st.toString(), workerId: id);
    } finally {
      // update stats
      _workload--;
      _totalWorkload++;
      _idle = DateTime.now().microsecondsSinceEpoch;
    }
  }

  /// Arguments to be passed when the [Isolate] is first started.
  List get startArguments;

  /// Creates the worker's [Isolate].
  Future<SendPort> start() async {
    final receiver = ReceivePort();
    final req = WorkerRequest.start(startArguments);
    await Isolate.spawn(_main, req.serialize(receiver));
    _commandPort = await receiver.first;
    if (_commandPort == null) throw Exception('Failed to create a new Isolate');
    onStarted();
    return _commandPort!;
  }

  /// Method called when the [Isolate] has been created.
  void onStarted() {
    _started = DateTime.now().microsecondsSinceEpoch;
    _idle = _started;
  }

  /// Stops this worker.
  void stop() {
    if (_stopped == null) {
      _stopped = DateTime.now().microsecondsSinceEpoch;
      final commandPort = _commandPort;
      if (commandPort != null) {
        _commandPort = null;
        final receiver = ReceivePort();
        commandPort.send(WorkerRequest.stop().serialize(receiver));
        receiver.close();
      }
    }
  }
}
