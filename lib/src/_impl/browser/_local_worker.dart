import 'dart:html' as web;

import '../../channel.dart';
import '../../exceptions/exception_manager.dart';
import '../../local_worker/local_worker.dart';
import '../../worker_service.dart';
import '../xplat/_worker_runner.dart';
import '_worker_runner.dart';

class _JsLocalWorker<W extends WorkerService> extends LocalWorker<W> {
  _JsLocalWorker._(super.service, ExceptionManager exceptionManager) {
    final runner = WorkerRunner.use(this);
    _port.port1.onMessage.listen(runner.handle);
    _channel =
        Channel.deserialize(_port.port2, runner.logger, exceptionManager);
  }

  final _port = web.MessageChannel();
  late Channel? _channel;

  @override
  Channel? get channel => _channel;

  @override
  void stop() {
    _port.port1.close();
    _port.port2.close();
    _channel?.close();
    _channel = null;
  }
}

/// Creates a [LocalWorker] on a browser platform.
LocalWorker<W> createLocalWorker<W extends WorkerService>(
        W service, ExceptionManager exceptionManager) =>
    _JsLocalWorker._(service, exceptionManager);
