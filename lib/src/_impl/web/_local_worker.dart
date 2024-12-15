import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../../channel.dart';
import '../../exceptions/exception_manager.dart';
import '../../local_worker/local_worker.dart';
import '../../worker_service.dart';
import '../xplat/_worker_runner.dart';
import '_worker_runner.dart';

base class _WebLocalWorker<W extends WorkerService> extends LocalWorker<W> {
  _WebLocalWorker._(super.service, ExceptionManager exceptionManager) {
    final runner = WorkerRunner.use(this);
    _port.port1.onmessage = runner.handle.toJS;
    _channel = Channel.deserialize(
        _port.port2, runner.internalLogger, exceptionManager);
  }

  final _port = web.MessageChannel();
  late Channel? _channel;

  @override
  Channel? get channel => _channel;

  @override
  FutureOr<void> start() {}

  @override
  void stop() {
    _port.port1.close();
    _port.port2.close();
    _channel?.close();
    _channel = null;
  }

  @override
  ExceptionManager get exceptionManager =>
      (_exceptionManager ??= ExceptionManager());
  ExceptionManager? _exceptionManager;
}

/// Creates a [LocalWorker] on a browser platform.
LocalWorker<W> createLocalWorker<W extends WorkerService>(
        W service, ExceptionManager exceptionManager) =>
    _WebLocalWorker._(service, exceptionManager);
