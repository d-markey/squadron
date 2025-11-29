import 'dart:js_interop';

import 'package:logger/web.dart';
import 'package:using/using.dart';
import 'package:web/web.dart' as web;

import '../../channel.dart';
import '../../exceptions/exception_manager.dart';
import '../../exceptions/task_terminated_exception.dart';
import '../../local_worker/local_worker.dart';
import '../../typedefs.dart';
import '../xplat/_worker_runner.dart';
import '_worker_runner.dart';

base class _WebLocalWorker<W> with Releasable implements LocalWorker<W> {
  _WebLocalWorker._(this.service, this.operations, this.exceptionManager) {
    final runner = WorkerRunner.use(this);
    _port.port1.onmessage = runner.handle.toJS;
    _channel = Channel.deserialize(
        _port.port2, runner.internalLogger, exceptionManager)
      ?..closed.then((_) {
        _port.port1.close();
        _port.port2.close();
      });
  }

  @override
  final W service;

  @override
  final OperationsMap operations;

  @override
  final ExceptionManager exceptionManager;

  @override
  Logger? channelLogger;

  final _port = web.MessageChannel();
  late Channel? _channel;

  @override
  Channel? get channel => _channel;

  @override
  Future<void> start() => Future.value();

  @override
  void stop() {
    _port.port1.close();
    _port.port2.close();
    _channel?.close();
    _channel = null;
  }

  @override
  void terminate([TaskTerminatedException? ex]) => stop();
}

/// Creates a [LocalWorker] on a browser platform.
LocalWorker<W> createLocalWorker<W>(W service, OperationsMap operations,
        ExceptionManager exceptionManager) =>
    _WebLocalWorker<W>._(service, operations, exceptionManager);
