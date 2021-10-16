import 'dart:async';

import 'package:squadron/squadron.dart';

import 'channel.dart';
import 'worker_exception.dart';
import 'worker_stat.dart';

typedef CommandHandler = FutureOr Function(WorkerRequest req);

/// Base worker class.
///
/// This base class takes care of creating the [Channel] and firing up the worker.
///
/// Typically, derived classes should add proxy methods sending [WorkerRequest]s to the worker.
abstract class Worker {
  /// Creates a [Worker] with the specified entrypoint
  Worker(this._entryPoint, {String? id, this.args = const []}) {
    this.id = id ?? hashCode.toString();
  }

  /// The [Worker]'s entry point
  /// Typically, a top-level function in native world or a JavaScript script Uri in browser world
  final dynamic _entryPoint;

  /// The [Worker]'s start arguments
  final List args;

  /// The [Worker] id
  late final String id;

  /// Start timestamp (in microseconds since Epoch)
  DateTime? get started => (_started == null)
      ? null
      : DateTime.fromMicrosecondsSinceEpoch(_started!);
  int? _started;

  /// Idle timestamp (in microseconds since Epoch)
  int? _idle;

  /// Stopped timestamp (in microseconds since Epoch)
  DateTime? get stopped => (_stopped == null)
      ? null
      : DateTime.fromMicrosecondsSinceEpoch(_stopped!);
  int? _stopped;

  /// Current workload
  int get workload => _workload;
  int _workload = 0;

  /// Maximum acceptable workload
  int get maxWorkload => _maxWorkload;
  int _maxWorkload = 0;

  /// Total processed workload
  int get totalWorkload => _totalWorkload;
  int _totalWorkload = 0;

  /// Total errors
  int get totalErrors => _totalErrors;
  int _totalErrors = 0;

  /// Up time
  Duration get upTime => (_started == null)
      ? Duration.zero
      : Duration(
          microseconds:
              (_stopped ?? DateTime.now().microsecondsSinceEpoch) - _started!);

  /// Idle time
  Duration get idleTime => (_workload > 0 || _idle == null)
      ? Duration.zero
      : Duration(microseconds: DateTime.now().microsecondsSinceEpoch - _idle!);

  /// Indicates if the [Worker] has been stopped
  bool get isStopped => _stopped != null;

  /// [Worker] status
  String get status {
    if (isStopped) {
      return 'STOPPED';
    } else if (_workload == 0) {
      return 'IDLE';
    } else {
      return 'WORKING($_workload)';
    }
  }

  /// [Worker] statistics
  WorkerStat get stats => WorkerStat(runtimeType, id, isStopped, status,
      workload, maxWorkload, totalWorkload, totalErrors, upTime, idleTime);

  /// [Channel] to communicate with the worker
  Channel? get channel => _channel;
  Channel? _channel;
  Future? _starting;

  /// Sends a workload to the worker
  Future<T> send<T>(int command, [List args = const []]) async {
    try {
      // update stats
      _workload++;
      if (_workload > _maxWorkload) {
        _maxWorkload = _workload;
      }

      // ensure the worker is up and running
      if (_channel == null) {
        await start();
      }

      // send request and return response
      return await channel!.sendRequest<T>(command, args);
    } on WorkerException catch (e) {
      // update stats and rethrow with worker id
      _totalErrors++;
      throw WorkerException(e.message, stackTrace: e.stackTrace, workerId: id);
    } catch (e, st) {
      // update stats and rethrow as a [WorkerException] with worker id
      _totalErrors++;
      throw WorkerException(e.toString(),
          stackTrace: st.toString(), workerId: id);
    } finally {
      // update stats
      _workload--;
      _totalWorkload++;
      _idle = DateTime.now().microsecondsSinceEpoch;
    }
  }

  /// Sends a streaming workload to the worker
  Stream<T> stream<T>(int command, [List args = const []]) async* {
    try {
      // update stats
      _workload++;
      if (_workload > _maxWorkload) {
        _maxWorkload = _workload;
      }

      // ensure the worker is up and running
      if (_channel == null) {
        await start();
      }

      // send request and stream response items
      await for (var res in _channel!.sendStreamingRequest<T>(command, args)) {
        yield res;
      }
    } on WorkerException catch (e) {
      // update stats and rethrow with worker id
      _totalErrors++;
      throw WorkerException(e.message, stackTrace: e.stackTrace, workerId: id);
    } catch (e, st) {
      // update stats and rethrow as a [WorkerException] with worker id
      _totalErrors++;
      throw WorkerException(e.toString(),
          stackTrace: st.toString(), workerId: id);
    } finally {
      // update stats
      _workload--;
      _totalWorkload++;
      _idle = DateTime.now().microsecondsSinceEpoch;
    }
  }

  /// Creates a [Channel] and starts the worker using the [_entryPoint].
  Future start() {
    if (_stopped != null) {
      throw Exception('Worker is stopped');
    }
    _starting ??= Channel.open(_entryPoint, args).then(onStarted);
    return _starting!;
  }

  /// Method called after the worker has been started.
  /// Override this method to add custom initialization.
  void onStarted(Channel channel) {
    _started = DateTime.now().microsecondsSinceEpoch;
    _idle = _started;
    _channel = channel;
  }

  /// Stops this worker.
  void stop() {
    if (_stopped == null) {
      _stopped = DateTime.now().microsecondsSinceEpoch;
      _channel?.close();
      _channel = null;
      _starting = null;
    }
  }

  /// Called by the platform worker upon startup, in response to a start [WorkerRequest].
  /// [channelInfo] is an opaque object sent back from the platform worker to the Squadron [Worker] and used to communicate with the platform worker.
  /// Typically, [channelInfo] would be a [SendPort] (native) or a [MessagePort] (browser).
  /// [operations] and [serviceOperations] are optional maps of command ids to command methods.
  /// The idea is to provide the actual map of supported commands in [serviceOperations] and an empty map in [operations].
  /// [operations] will be populated with entries from [serviceOperations].
  /// If [operations] is not empty, it should mean that [connect] has already been called.
  /// [operations] make it easier to implement the [Worker]'s message handler.
  /// See also [process].
  static void connect(Channel? client, Object incoming,
      {Map<int, CommandHandler>? operations,
      Map<int, CommandHandler>? serviceOperations}) {
    if (client == null) {
      print('Missing client for connection request');
      return;
    }
    try {
      if (operations?.isNotEmpty ?? false) {
        client.reply(WorkerResponse.withError(
            'Already connected', StackTrace.current.toString()));
        return;
      }
      client.connect(incoming);
      operations?.addAll(serviceOperations ?? {});
    } on WorkerException catch (e) {
      client.reply(WorkerResponse.withError(e.message, e.stackTrace));
    } catch (e, st) {
      client.reply(WorkerResponse.withError(e.toString(), st.toString()));
    }
  }

  /// Generic [WorkerRequest] handler based on a map of command ids/command methods.
  /// [operations] contains the map of commands used to
  static void process(
      Map<int, CommandHandler> operations, WorkerRequest request) async {
    // start and termination requests must be handled beforehand
    if (request.connect || request.terminate) {
      request.client?.reply(WorkerResponse.withError(
          'Unhandled start or termination request: $request',
          StackTrace.current.toString()));
      print('Unhandled start or termination request: $request');
      return;
    }

    // retrieve client from the request (must be set)
    final client = request.client;
    if (client == null) {
      print('Missing client for request: $request');
      return;
    }

    try {
      // commands are not available yet (maybe connect() wasn't called or awaited)
      if (operations.isEmpty) {
        client.reply(WorkerResponse.withError(
            'Worker service is not ready', StackTrace.current.toString()));
        return;
      }
      // retrieve operation matching the request command
      final op = operations[request.command];
      if (op == null) {
        // unknown command
        client.reply(WorkerResponse.withError(
            'Unknown command: $request', StackTrace.current.toString()));
        return;
      }
      // process
      final result = op(request);
      if (result is Future) {
        // send future result to the client
        client.reply(WorkerResponse(await result));
      } else if (result is Stream) {
        // stream values to the client
        await for (var res in result) {
          client.reply(WorkerResponse(res));
        }
        // close the stream
        client.reply(WorkerResponse.endOfStream());
      } else {
        // send result to client
        client.reply(WorkerResponse(result));
      }
    } on WorkerException catch (e) {
      // send worker exception to the client
      client.reply(WorkerResponse.withError(e.message, e.stackTrace));
    } catch (e, st) {
      // send exception to the client
      client.reply(WorkerResponse.withError(e.toString(), st.toString()));
    }
  }
}
