import 'dart:async';
import 'dart:isolate';

import 'package:logger/web.dart';
import 'package:using/using.dart';

import '../../channel.dart';
import '../../exceptions/exception_manager.dart';
import '../../exceptions/task_terminated_exception.dart';
import '../../local_worker/local_worker.dart';
import '../../typedefs.dart';
import '../xplat/_worker_runner.dart';
import '_worker_runner.dart';

base class _VmLocalWorker<W> with Releasable implements LocalWorker<W> {
  _VmLocalWorker._(this.service, this.operations, this.exceptionManager) {
    final runner = WorkerRunner.use(this);
    _port.listen(runner.handle);
    _channel = Channel.deserialize(
        _port.sendPort, runner.internalLogger, exceptionManager)!
      ..closed.then((_) => _port.close());
  }

  @override
  final W service;

  @override
  final OperationsMap operations;

  @override
  final ExceptionManager exceptionManager;

  @override
  Logger? channelLogger;

  final _port = ReceivePort();
  late Channel? _channel;

  @override
  Channel? get channel => _channel;

  @override
  FutureOr<void> start() {}

  @override
  void stop() {
    _port.close();
    _channel?.close();
    _channel = null;
  }

  @override
  void terminate([TaskTerminatedException? ex]) => stop();
}

/// Creates a [LocalWorker] on a native platform.
LocalWorker<W> createLocalWorker<W>(W service, OperationsMap operations,
        ExceptionManager exceptionManager) =>
    _VmLocalWorker<W>._(service, operations, exceptionManager);
